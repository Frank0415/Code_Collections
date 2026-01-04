#pragma once

template <int n> class factorial
{
public:
  static const long long int value = n * factorial<n - 1>::value;
};

template <> class factorial<0>
{
public:
  static const long long int value = 1;
};