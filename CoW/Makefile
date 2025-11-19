CXX = g++
CXXFLAGS = -std=c++11 -Wall -Wextra -O2
TARGET = cow_demo
SRCS = main.cpp
HEADERS = resource.hpp cow.hpp

$(TARGET): $(SRCS) $(HEADERS)
	$(CXX) $(CXXFLAGS) $(SRCS) -o $(TARGET)

clean:
	rm -f $(TARGET)

.PHONY: clean