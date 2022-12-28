use fake::{Fake, Faker};
use influx_faker::*;
use rand::Rng;
use std::env::args;
use std::error::Error;
use std::net::ToSocketAddrs;
use std::net::UdpSocket;

fn random_line<R: Rng>(rng: &mut R) -> String {
    let alt: Vec<fn() -> String> = vec![
        || Faker.fake::<Swap>().to_string(),
        || Faker.fake::<DiskIO>().to_string(),
        || Faker.fake::<Cpu>().to_string(),
        || Faker.fake::<Disk>().to_string(),
    ];
    alt[rng.gen::<usize>() % alt.len()]()
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
        let line = random_line(&mut rng);
        socket
            .send_to(&line.as_bytes(), &addr)
            .expect("failed to send message");
    }
    Ok(())
}
