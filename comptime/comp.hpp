#pragma once

template <int n> class factorial
{
  static const int value = n * factorial<n - 1>::value;
};

template <> class factorial<0>
{
  static const int value = 1;
};