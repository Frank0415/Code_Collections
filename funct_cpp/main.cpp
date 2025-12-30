#include "funct.hpp"
#include <algorithm>
#include <functional>
#include <iostream>
#include <map>
#include <string>
#include <vector>

void print_vec(const std::vector<int>& vec)
{
  for (const auto& v : vec)
    std::cout << v << " ";
  std::cout << std::endl;
}

int main()
{
  std::vector<int> vec{1, 2, 3, 4, 5};
  auto adder_2 = adder(2);
  std::transform(vec.begin(), vec.end(), vec.begin(), adder_2);
  print_vec(vec);

  std::transform(vec.begin(), vec.end(), vec.begin(), add_3);
  print_vec(vec);

  auto lambda_1 = adder_lambda(1);
  std::transform(vec.begin(), vec.end(), vec.begin(), lambda_1);
  print_vec(vec);

  std::sort(vec.begin(), vec.end(), [](int x, int y) { return x > y; });
  print_vec(vec);
  return 0;

  int a = 3;

  auto fooinit = [&]() -> foo
  {
    switch (a)
    {
    case 3:
      return foo(1, 2, 3);
      break;
    default:
      return foo(0, 0, 0);
    }
  };

  auto funcc = std::map<std::string, std::function<int(int, int)>>{
      {"+", [](int x, int y) { return x + y; }}, {"-", [](int x, int y) { return x - y; }}};

  std::cout << funcc["+"](1, 2) << std::endl;
}