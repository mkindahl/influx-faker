use fake::{Fake, Faker};
use influx_faker::*;
use rand::Rng;
use std::env::args;
use std::error::Error;
use std::net::{ToSocketAddrs, UdpSocket};
use std::time::SystemTime;

macro_rules! generator {
    ($kind:ty, $ts:ident) => {
        |$ts| {
            let mut obj = Faker.fake::<$kind>();
            obj.timestamp = $ts;
            obj.to_string()
        }
    };
}

fn random_line<R: Rng>(rng: &mut R, ts: u128) -> String {
    let alt: Vec<fn(u128) -> String> = vec![
        generator!(Swap, ts),
        generator!(DiskIO, ts),
        generator!(Cpu, ts),
        generator!(Disk, ts),
    ];
    alt[rng.gen::<usize>() % alt.len()](ts)
}

fn main() -> Result<(), Box<dyn Error>> {
    let mut rng = rand::thread_rng();
    let addr_string: String = args().nth(1).unwrap();
    let mut addrs = addr_string.as_str().to_socket_addrs().unwrap();
    let addr = addrs.next().unwrap();
    let count: usize = match args().nth(2) {
        Some(x) => x.parse()?,
        None => 100000,
    };
    println!("Sending {} lines to {}", count, addr);
    for _ in 1..count {
        // We create a new socket in each iteration to get a new source port.
        let socket = UdpSocket::bind("0.0.0.0:0")?;
        let ts = SystemTime::now()
            .duration_since(SystemTime::UNIX_EPOCH)?
            .as_nanos();
        let line = random_line(&mut rng, ts);
        socket
            .send_to(&line.as_bytes(), &addr)
            .expect("failed to send message");
    }
    Ok(())
}
