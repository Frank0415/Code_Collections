#ifndef LRU_HPP
#define LRU_HPP

#include <list>
#include <map>
#include <optional>
#include <string>

class LRU
{
private:
  size_t capacity;
  std::list<std::string> itemList;
  std::map<int, std::list<std::string>::iterator> itemMap;

  void _put_first(int idx); // need valid id
  void _remove_last();

public:
  LRU();
  ~LRU() = default;

  //

  std::optional<std::string> getitem(int idx);
  void dumplist();

  bool remove(int idx);

  bool insert(int idx, std::string&& str);
};


#endif