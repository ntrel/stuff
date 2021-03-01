#include <memory>
#include <iostream>

struct S
{
	std::shared_ptr<int> c;
	
	S(int i) {
		c = std::make_shared<int>(i);
	}
	
	void reset(const int& i) {
		std::cout << i << std::endl;
		c = std::shared_ptr<int>(new int);
		std::cout << i; // reads freed memory
	}
};

int main()
{
	auto s = S(5);
	s.reset(*s.c);
	return 0;
}

