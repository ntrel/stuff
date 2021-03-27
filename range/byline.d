import std.stdio;// : File;
import std.range;
import consumable;

struct ByLineImpl
{
	File file;
	char[] line;
	char[] buffer;
	auto terminator = '\n';

	Optional!(char[]) next()
	{
		import std.algorithm.searching : endsWith;
		assert(file.isOpen);
		line = buffer;
		file.readln(line, terminator);
		if (line.length > buffer.length)
		{
			buffer = line;
		}
		if (line.empty)
		{
			file.detach();
			line = null;
			return Optional!(char[])();
		}
		return just(line);
	}
}
static assert(isConsumable!(ByLineImpl));
import std.traits;
pragma(msg, typeof(lvalueOf!ByLineImpl.next()));
//~ static assert(isInstanceOf!Optional(typeof(lvalueOf!ByLineImpl.next())));

unittest
{
	import filter;
	auto c = ByLineImpl(File("byline.d")).filter!(l => l != "\r");
	while(1)
	{
		auto opt = c.next;
		if (opt.empty)
			break;
		opt.unwrap.writeln;
	}
}
