#include "cow.hpp"
#include "resource.hpp"
#include <chrono>
#include <iostream>

void test_normal_copy()
{
  std::cout << "\n=== Testing Normal Copy ===" << std::endl;

  auto start = std::chrono::high_resolution_clock::now();
  Resource r1;
  auto end = std::chrono::high_resolution_clock::now();
  std::chrono::duration<double> elapsed = end - start;
  std::cout << "Allocation time: " << elapsed.count() << " seconds" << std::endl;

  start = std::chrono::high_resolution_clock::now();
  Resource r2 = r1; // Expensive copy
  end = std::chrono::high_resolution_clock::now();
  elapsed = end - start;
  std::cout << "Copy time: " << elapsed.count() << " seconds" << std::endl;

  start = std::chrono::high_resolution_clock::now();
  Resource r3 = r2; // Another expensive copy
  end = std::chrono::high_resolution_clock::now();
  elapsed = end - start;
  std::cout << "Second copy time: " << elapsed.count() << " seconds" << std::endl;

  // Modify r2
  start = std::chrono::high_resolution_clock::now();
  r2.modify(0, 999);
  end = std::chrono::high_resolution_clock::now();
  elapsed = end - start;
  std::cout << "Modify time: " << elapsed.count() << " seconds" << std::endl;

  std::cout << "r1[0] = " << r1.get(0) << std::endl;
  std::cout << "r2[0] = " << r2.get(0) << std::endl;
  std::cout << "r3[0] = " << r3.get(0) << std::endl;
}

void test_CoW_copy()
{
  std::cout << "\n=== Testing CoW Copy ===" << std::endl;

  auto start = std::chrono::high_resolution_clock::now();
  CoWResource r1;
  auto end = std::chrono::high_resolution_clock::now();
  std::chrono::duration<double> elapsed = end - start;
  std::cout << "Allocation time: " << elapsed.count() << " seconds" << std::endl;
  std::cout << "Use count: " << r1.use_count() << std::endl;

  start = std::chrono::high_resolution_clock::now();
  CoWResource r2 = r1; // Cheap copy (sharing)
  end = std::chrono::high_resolution_clock::now();
  elapsed = end - start;
  std::cout << "CoW copy time: " << elapsed.count() << " seconds" << std::endl;
  std::cout << "Use count after copy: " << r1.use_count() << ", " << r2.use_count() << std::endl;

  start = std::chrono::high_resolution_clock::now();
  CoWResource r3 = r2; // Another cheap copy
  end = std::chrono::high_resolution_clock::now();
  elapsed = end - start;
  std::cout << "Second CoW copy time: " << elapsed.count() << " seconds" << std::endl;
  std::cout << "Use count after second copy: " << r1.use_count() << ", " << r2.use_count() << ", "
            << r3.use_count() << std::endl;

  // Modify r2 (should trigger copy-on-write)
  start = std::chrono::high_resolution_clock::now();
  r2.modify(0, 999);
  end = std::chrono::high_resolution_clock::now();
  elapsed = end - start;
  std::cout << "CoW modify time: " << elapsed.count() << " seconds" << std::endl;
  std::cout << "Use count after modify: " << r1.use_count() << ", " << r2.use_count() << ", "
            << r3.use_count() << std::endl;

  std::cout << "r1[0] = " << r1.get(0) << std::endl;
  std::cout << "r2[0] = " << r2.get(0) << std::endl;
  std::cout << "r3[0] = " << r3.get(0) << std::endl;
}

int main()
{
  test_normal_copy();
  test_CoW_copy();

  return 0;
}