// Tested with rustc 0.11.0

#![feature(macro_rules)]


// TODO: scope_exit!($finally) to support continue
macro_rules! cfor(
    (; $cond:expr; $finally:expr $body:block) =>
    (
        loop {
            if $cond {
                break
            }
            $body;
            $finally;
        }
    );
    
    ($var:ident = $init:expr; $cond:expr; $finally:expr $body:block) =>
    (
        // workaround: macros only expand to one statement - #10681
        {
            $var = $init;
            cfor!(; $cond; $finally $body);
        }
    );
    
    // doesn't work - can't use $var in arguments
    // error: unresolved name `x` for 'x < 10'
    //~ cfor!(let mut x = 1u; x < 10; x *= 2 {
        //~ println!("{}", x);
    //~ });
    (let $var:pat = $init:expr; $cond:expr; $finally:expr $body:block) =>
    (
        {
            let $var = $init;
            cfor!(; $cond; $finally $body);
        }
    )
)

fn main()
{
    let mut y;
    cfor!(y = 0u; y < 5; y += 1 {
        println!("{}", y);
    });
    cfor!(y = 1; y < 10; y *= 2 {
        println!("{}", y);
    });
    //~ cfor!(let mut x = 1u; |x|x < 10; |x|x *= 2 |x|{
    //~ });
}

