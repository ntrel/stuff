// Tested with rustc 0.11.0

#![feature(macro_rules)]
#![feature(unsafe_destructor)]

// taken from std::finally
struct Finallyalizer<'a,A> {
    mutate: &'a mut A,
    dtor: |&mut A|: 'a
} 

#[unsafe_destructor] 
impl<'a,A> Drop for Finallyalizer<'a,A> {
    #[inline]
    fn drop(&mut self) {
        (self.dtor)(self.mutate);
    }
} 

#[allow(unused_variable)]   // but f is not unused (drop)
fn main()
{
    let mut x = 0u;
    while x < 5
    {
        let f = Finallyalizer {
            mutate: &mut x,
            dtor: |i|*i += 1
        };
        //~ if x == 1 {return}  // error: cannot use `x` because it was mutably borrowed
        //~ println!("{}", x);  // error: cannot borrow `x` as immutable because it is also borrowed as mutable
    }
    println!("{}", x);
}

#[allow(dead_code)]
fn bad()
{
    let mut x = 0u;
    // closure captures x uniquely
    let f = ||x += 1;
    //~ if x == 1 {return}  // error: cannot use `x` because it was mutably borrowed
    //~ println!("{}", x);  // error: cannot borrow `x` as immutable because it is also borrowed as mutable
    f();
    //~ scope_exit!(
    test();
}

// FIXME
// can Dropper store a stack closure?
macro_rules! scope_exit(
    //~ ($e:expr) => (let s = Dropper{|| e};);
    ($b:block, $f:expr) => ((||$b).finally(||{$f}));
)
    

// C-style for
fn test()
{
    // print 0,2,4
    let mut x = 0u;
    while x < 5
    {
        //~ scope_exit!(x += 1);
        x += 1;
        if x & 1 > 0
        {
            continue;
        }
        println!("{}", x);
    }
}
