#include "Master.hpp"

auto Memory::getitem(int idx) -> rettype
{
  for (auto& item : mem)
  {
    if (item.first == idx)
    {
      return item;
    }
  }
  return std::nullopt;
}

auto Memory::getitem(const std::string& str) -> rettype
{
  for (auto& item : mem)
  {
    if (item.second == str)
    {
      return item;
    }
  }
  return std::nullopt;
}

void Memory::insert(std::pair<int, std::string> dat)
{
  mem.push_back(std::move(dat));
}

void Master::store(int idx, std::string value)
{
  mem.insert({idx, std::move(value)});
}

auto Master::fetch(int idx) -> str
{
  if (auto cached = cache.getitem(idx))
  {
    return cached;
  }

  if (auto stored = mem.getitem(idx))
  {
    cache.insert(idx, std::string(stored->second));
    return stored->second;
  }

  return std::nullopt;
}

void Master::dump_cache()
{
  cache.dumplist();
}
