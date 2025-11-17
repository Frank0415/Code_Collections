#include "LRU.hpp"

#include <iostream>

namespace
{
constexpr size_t kDefaultCapacity = 20;
}

void LRU::_put_first(int idx)
{
  auto iter = itemMap.find(idx);
  itemList.push_front(std::move(*iter->second));
  itemList.erase(iter->second);
  iter->second = itemList.begin();
}

std::optional<std::string> LRU::getitem(int idx)
{
  auto iter = itemMap.find(idx);
  if (iter == itemMap.end())
  {
    return std::nullopt;
  }
  _put_first(idx);
  return *iter->second;
}

void LRU::dumplist()
{
  if (itemMap.size() == 0)
  {
    return;
  }
  int idx = 1;
  int changeline = 0;
  for (auto& iter : itemList)
  {
    std::cout << idx << "th item is: " << iter;
    idx++;
    if (changeline == 3)
    {
      std::cout << '\n';
      changeline = 0;
    }
    else
    {
      std::cout << '\t';
      changeline++;
    }
  }
}

LRU::LRU() : capacity(kDefaultCapacity)
{
}

bool LRU::remove(int idx)
{
  auto map_it = itemMap.find(idx);
  if (map_it == itemMap.end())
  {
    return false;
  }
  auto list_it = map_it->second;
  itemMap.erase(map_it);
  itemList.erase(list_it);
  return true;
}

bool LRU::insert(int idx, std::string&& str)
{
  if (itemMap.size() == capacity)
  {
    _remove_last();
  }
  itemList.push_front(std::move(str));
  itemMap.insert({idx, itemList.begin()});
  return true;
}

void LRU::_remove_last()
{
  if (itemList.empty())
  {
    return;
  }

  auto last_it = std::prev(itemList.end());
  int key_to_remove = -1;
  for (auto& pair : itemMap)
  {
    if (pair.second == last_it)
    {
      key_to_remove = pair.first;
      break;
    }
  }
  if (key_to_remove != -1)
  {
    itemMap.erase(key_to_remove);
  }
  itemList.pop_back();
}