#include <memory>
#include <iostream>

// from std
template <class T, class... Args>
std::shared_ptr<T> make_shared (Args&&... args)
{
	return std::shared_ptr<T>(new T(args...));
}

// why not have this?
template <class T>
std::shared_ptr<T> make_shared(T&& arg)
{
	return std::shared_ptr<T>(new T(arg));
}

int main()
{
	//auto c = std::make_shared<int>(5);
	auto c = make_shared(5);
	std::cout << *c << std::endl;
	return 0;
}

