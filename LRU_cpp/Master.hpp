#ifndef MASTER_HPP
#define MASTER_HPP

#include <optional>
#include <string>
#include <utility>
#include <vector>

#include "LRU.hpp"

class Memory
{

private:
  using datatype = std::pair<int, std::string>;
  using rettype = std::optional<datatype>;
  std::vector<datatype> mem;

public:
  rettype getitem(int idx);
  rettype getitem(const std::string& str);
  void insert(datatype dat);
};

class Master
{
private:
  using str = std::optional<std::string>;
  LRU cache;
  Memory mem;

public:
  void store(int idx, std::string value);
  str fetch(int idx);
  void dump_cache();
};

#endif