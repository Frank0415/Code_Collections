#ifndef RESOURCE_HPP
#define RESOURCE_HPP

#include <vector>
#include <chrono>
#include <thread>
#include <iostream>

class Resource {
private:
    std::vector<int> data;
    static const size_t SIZE = 1000000; // 1 million elements

public:
    Resource() {
        // Simulate expensive allocation
        std::cout << "Allocating resource..." << std::endl;
        std::this_thread::sleep_for(std::chrono::milliseconds(100)); // 100ms delay
        data.resize(SIZE);
        for (size_t i = 0; i < SIZE; ++i) {
            data[i] = i;
        }
        std::cout << "Resource allocated." << std::endl;
    }

    Resource(const Resource& other) {
        // Simulate expensive copy
        std::cout << "Copying resource..." << std::endl;
        std::this_thread::sleep_for(std::chrono::milliseconds(100)); // 100ms delay
        data = other.data;
        std::cout << "Resource copied." << std::endl;
    }

    Resource& operator=(const Resource& other) {
        if (this != &other) {
            // Simulate expensive copy
            std::cout << "Assigning resource..." << std::endl;
            std::this_thread::sleep_for(std::chrono::milliseconds(100)); // 100ms delay
            data = other.data;
            std::cout << "Resource assigned." << std::endl;
        }
        return *this;
    }

    void modify(size_t index, int value) {
        if (index < data.size()) {
            data[index] = value;
        }
    }

    int get(size_t index) const {
        if (index < data.size()) {
            return data[index];
        }
        return -1;
    }

    size_t size() const {
        return data.size();
    }
};

#endif