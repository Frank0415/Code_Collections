#include "Master.hpp"
#include <iostream>
#include <random>
#include <vector>

int main()
{
  Master master;
  constexpr int kSeed = 42;
  constexpr int kMaxIndex = 399;
  std::mt19937 gen(kSeed);                            // Fixed seed for reproducibility
  std::uniform_int_distribution<> dist(0, kMaxIndex); // Random indices up to kMaxIndex

  // Sequential store: store 200 entries sequentially
  constexpr int kSeqStore = 200;
  for (int i = 0; i < kSeqStore; ++i)
  {
    master.store(i, "seq-value-" + std::to_string(i));
  }
  std::cout << "Stored " << kSeqStore << " sequential entries.\n";

  // Random store: store 200 random entries
  constexpr int kRandStore = 200;
  std::vector<int> random_indices;
  for (int i = 0; i < kRandStore; ++i)
  {
    int idx = dist(gen);
    random_indices.push_back(idx);
    master.store(idx, "rand-value-" + std::to_string(idx));
  }
  std::cout << "Stored " << kRandStore << " random entries.\n";

  // Sequential read: fetch the first 100 entries
  int seq_hits = 0;
  int seq_misses = 0;
  for (int i = 0; i < kSeqStore; ++i)
  {
    auto result = master.fetch(i);
    if (result)
    {
      ++seq_hits;
    }
    else
    {
      ++seq_misses;
    }
  }
  std::cout << "Sequential reads: hits=" << seq_hits << ", misses=" << seq_misses << '\n';

  // Random read: fetch the random indices
  int rand_hits = 0;
  int rand_misses = 0;
  for (int idx : random_indices)
  {
    auto result = master.fetch(idx);
    if (result)
    {
      ++rand_hits;
    }
    else
    {
      ++rand_misses;
    }
  }
  std::cout << "Random reads: hits=" << rand_hits << ", misses=" << rand_misses << '\n';

  // Additional random queries to simulate more workload
  constexpr int kExtraQueries = 2000000;
  int extra_hits = 0;
  int extra_misses = 0;
  for (int query = 0; query < kExtraQueries; ++query)
  {
    int idx = dist(gen);
    auto result = master.fetch(idx);
    if (result)
    {
      ++extra_hits;
    }
    else
    {
      ++extra_misses;
    }
  }
  std::cout << "Extra random queries: hits=" << extra_hits << ", misses=" << extra_misses << '\n';

  // Dump all items in cache at the end
  std::cout << "\nDumping cache contents:\n";
  master.dump_cache();

  return 0;
}