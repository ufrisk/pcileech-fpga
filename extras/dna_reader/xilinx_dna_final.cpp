#include <windows.h>
#include <iostream>
#include <iomanip>

typedef PVOID FT_HANDLE;
typedef ULONG FT_STATUS;

#define FT_OK 0
#define FT_OPEN_BY_INDEX 8

typedef FT_STATUS (WINAPI *PFT_Create)(PVOID, DWORD, FT_HANDLE*);
typedef FT_STATUS (WINAPI *PFT_Close)(FT_HANDLE);
typedef FT_STATUS (WINAPI *PFT_WritePipe)(FT_HANDLE, UCHAR, PUCHAR, ULONG, PULONG, LPOVERLAPPED);
typedef FT_STATUS (WINAPI *PFT_ReadPipe)(FT_HANDLE, UCHAR, PUCHAR, ULONG, PULONG, LPOVERLAPPED);
typedef FT_STATUS (WINAPI *PFT_SetStreamPipe)(FT_HANDLE, BOOL, BOOL, UCHAR, ULONG);

PFT_Create pFT_Create;
PFT_Close pFT_Close;
PFT_WritePipe pFT_WritePipe;
PFT_ReadPipe pFT_ReadPipe;
PFT_SetStreamPipe pFT_SetStreamPipe;

#define EP_OUT 0x02
#define EP_IN 0x82

bool LoadFTD3XX() {
    HMODULE hDll = LoadLibraryA("FTD3XX.dll");
    if (!hDll) return false;

    pFT_Create = (PFT_Create)GetProcAddress(hDll, "FT_Create");
    pFT_Close = (PFT_Close)GetProcAddress(hDll, "FT_Close");
    pFT_WritePipe = (PFT_WritePipe)GetProcAddress(hDll, "FT_WritePipe");
    pFT_ReadPipe = (PFT_ReadPipe)GetProcAddress(hDll, "FT_ReadPipe");
    pFT_SetStreamPipe = (PFT_SetStreamPipe)GetProcAddress(hDll, "FT_SetStreamPipe");

    return (pFT_Create && pFT_Close && pFT_WritePipe && pFT_ReadPipe);
}

bool ReadRegister16(FT_HANDLE handle, uint16_t addr, uint16_t* value) {
    uint8_t cmd[8] = {0};
    cmd[4] = (addr >> 8) & 0xFF;
    cmd[5] = addr & 0xFF;
    cmd[6] = 0x10 | 0x03;
    cmd[7] = 0x77;

    ULONG bytesWritten = 0;
    if (pFT_WritePipe(handle, EP_OUT, cmd, 8, &bytesWritten, nullptr) != FT_OK) {
        return false;
    }

    Sleep(100);

    uint8_t buffer[4096];
    ULONG bytesRead = 0;
    if (pFT_ReadPipe(handle, EP_IN, buffer, sizeof(buffer), &bytesRead, nullptr) != FT_OK) {
        return false;
    }

    for (ULONG j = 20; j + 8 <= bytesRead; j += 4) {
        uint32_t dword1 = *(uint32_t*)(buffer + j);
        if (dword1 == 0x55556666) continue;

        if ((dword1 & 0x03) == 0x03) {
            uint32_t dword2 = *(uint32_t*)(buffer + j + 4);
            uint16_t resp_addr = dword2 & 0xFFFF;
            uint16_t resp_data = (dword2 >> 16) & 0xFFFF;
            resp_addr = ((resp_addr & 0xFF) << 8) | ((resp_addr >> 8) & 0xFF);

            if (resp_addr == addr) {
                *value = resp_data;
                return true;
            }
        }
    }

    return false;
}

int main() {
    std::cout << "=== Xilinx Series7 FPGA DNA Reader ===" << std::endl;

    if (!LoadFTD3XX()) {
        std::cerr << "Failed to load FTD3XX.dll" << std::endl;
        return 1;
    }

    FT_HANDLE handle;
    if (pFT_Create((PVOID)0, FT_OPEN_BY_INDEX, &handle) != FT_OK) {
        std::cerr << "Failed to open device" << std::endl;
        return 1;
    }

    if (pFT_SetStreamPipe) {
        pFT_SetStreamPipe(handle, FALSE, FALSE, EP_OUT, 0);
        pFT_SetStreamPipe(handle, FALSE, FALSE, EP_IN, 0);
    }

    // Clear FIFO
    for (int i = 0; i < 10; i++) {
        uint8_t dummy[4096];
        ULONG bytesRead = 0;
        pFT_ReadPipe(handle, EP_IN, dummy, sizeof(dummy), &bytesRead, nullptr);
        Sleep(10);
    }

    std::cout << "\nReading Device DNA..." << std::endl;

    uint16_t dna_word0, dna_word1, dna_word2, dna_word3;

    bool ok1 = ReadRegister16(handle, 0x0028, &dna_word0);
    bool ok2 = ReadRegister16(handle, 0x002A, &dna_word1);
    bool ok3 = ReadRegister16(handle, 0x002C, &dna_word2);
    bool ok4 = ReadRegister16(handle, 0x002E, &dna_word3);

    if (ok1 && ok2 && ok3 && ok4) {
        // Combine into 64-bit value
        uint64_t dna_raw = ((uint64_t)dna_word3 << 48) |
                           ((uint64_t)dna_word2 << 32) |
                           ((uint64_t)dna_word1 << 16) |
                           dna_word0;

        // Mask to 57 bits (DNA is only 57 bits)
        uint64_t dna = dna_raw & 0x1FFFFFFFFFFFFFF;

        // Print in JTAG-compatible format
        std::cout << "\nDNA = ";

        // Print as 57-bit binary
        for (int i = 56; i >= 0; i--) {
            std::cout << ((dna >> i) & 1);
        }

        std::cout << " (0x" << std::hex << std::setw(16) << std::setfill('0')
                  << dna << ")" << std::dec << std::endl;

        std::cout << "\nRaw Register Values:" << std::endl;
        std::cout << "  0x0028: 0x" << std::hex << std::setw(4) << std::setfill('0') << dna_word0 << std::dec << std::endl;
        std::cout << "  0x002A: 0x" << std::hex << std::setw(4) << std::setfill('0') << dna_word1 << std::dec << std::endl;
        std::cout << "  0x002C: 0x" << std::hex << std::setw(4) << std::setfill('0') << dna_word2 << std::dec << std::endl;
        std::cout << "  0x002E: 0x" << std::hex << std::setw(4) << std::setfill('0') << dna_word3 << " (masked to 0x"
                  << std::setw(4) << std::setfill('0') << (dna_word3 & 0x1FF) << ")" << std::dec << std::endl;

        std::cout << "\nCombined (64-bit): 0x" << std::hex << std::setw(16) << std::setfill('0')
                  << dna_raw << std::dec << std::endl;
        std::cout << "DNA (57-bit):      0x" << std::hex << std::setw(16) << std::setfill('0')
                  << dna << std::dec << std::endl;
    } else {
        std::cerr << "\nFailed to read DNA" << std::endl;
        std::cerr << "  Status: ok1=" << ok1 << " ok2=" << ok2 << " ok3=" << ok3 << " ok4=" << ok4 << std::endl;
    }

    pFT_Close(handle);

    std::cout << "\nPress Enter to exit..." << std::endl;
    std::cin.get();
    return 0;
}
