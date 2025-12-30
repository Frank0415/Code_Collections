#pragma once

class adder
{
public:
  adder(int n) : n_(n) {};
  int operator()(int x) const
  {
    return x + n_;
  }

private:
  int n_;
};

int add_3(int x)
{
  return x + 3;
}

auto adder_lambda = [](int n) { return [n](int x) { return x + n; }; };

class foo
{
public:
  foo(int a, int b, int c) : a(a), b(b), c(c) {};

private:
  int a;
  int b;
  int c;
};


