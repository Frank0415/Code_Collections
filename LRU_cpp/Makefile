CXX := g++
CXXFLAGS := -std=c++17 -Wall -Wextra -Wpedantic -O2

SRCS := LRU.cpp Master.cpp main.cpp
OBJS := $(SRCS:.cpp=.o)
TARGET := lru_cache

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CXX) $(CXXFLAGS) -o $@ $^

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

run: $(TARGET)
	./$(TARGET)

clean:
	rm -f $(OBJS) $(TARGET)

.PHONY: all run clean
