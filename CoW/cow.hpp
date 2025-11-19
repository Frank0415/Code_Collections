#ifndef CoW_HPP
#define CoW_HPP

#include "resource.hpp"
#include <memory>
#include <iostream>

class CoWResource {
private:
    std::shared_ptr<Resource> resource;

public:
    CoWResource() : resource(std::make_shared<Resource>()) {}

    CoWResource(const CoWResource& other) : resource(other.resource) {
        std::cout << "CoW copy: sharing resource." << std::endl;
    }

    CoWResource& operator=(const CoWResource& other) {
        if (this != &other) {
            resource = other.resource;
            std::cout << "CoW assignment: sharing resource." << std::endl;
        }
        return *this;
    }

    void modify(size_t index, int value) {
        // Copy-on-write: if shared, create a copy
        if (resource.use_count() > 1) {
            std::cout << "CoW: copying on write..." << std::endl;
            resource = std::make_shared<Resource>(*resource);
        }
        resource->modify(index, value);
    }

    int get(size_t index) const {
        return resource->get(index);
    }

    size_t size() const {
        return resource->size();
    }

    size_t use_count() const {
        return resource.use_count();
    }
};

#endif