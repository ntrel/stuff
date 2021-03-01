#include <memory>
#include <iostream>

void f(std::shared_ptr<int>& c, const int& i) {
	std::cout << i << std::endl;
	c = std::shared_ptr<int>(new int);
	std::cout << i; // reads freed memory
}

int main()
{
	auto c = std::shared_ptr<int>(new int);
	*c = 5;
	std::cout << *c << std::endl;
	f(c, *c);
	return 0;
}

