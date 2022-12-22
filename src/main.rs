use fake::faker::filesystem::raw::*;
use fake::faker::lorem::raw::*;
use fake::locales::EN;
use fake::{Fake, Faker};
use influx_faker::*;
use rand::Rng;
use std::env::args;
use std::error::Error;
use std::net::ToSocketAddrs;
use std::net::UdpSocket;

fn fake_disk() -> String {
    format!("disk,device={},fstype={},host={},mode={},path={} free={}i,inodes_free={}i,inodes_total={}i,inodes_used={}i,total={}i,used={}i,used_percent={} {}\n",
            Word(EN).fake::<String>(),
            Word(EN).fake::<String>(),
            Word(EN).fake::<String>(),
            Word(EN).fake::<String>(),
            FilePath(EN).fake::<String>(),
            Faker.fake::<u32>(),
            Faker.fake::<u32>(),
            Faker.fake::<u32>(),
            Faker.fake::<u32>(),
            Faker.fake::<u32>(),
            Faker.fake::<u32>(),
            (0.0..100.0).fake::<f32>(),
            Faker.fake::<u64>()
    )
}

fn random_line<R: Rng>(rng: &mut R) -> String {
    let alt: Vec<fn() -> String> = vec![
        || Faker.fake::<Swap>().to_string(),
        || Faker.fake::<DiskIO>().to_string(),
        || Faker.fake::<Cpu>().to_string(),
        fake_disk,
    ];
    alt[rng.gen::<usize>() % alt.len()]()
}

fn main() -> Result<(), Box<dyn Error>> {
    let socket = UdpSocket::bind("0.0.0.0:0")?;
    let mut rng = rand::thread_rng();
    let addr_string: String = args().nth(1).unwrap();
    let mut addrs = addr_string.as_str().to_socket_addrs().unwrap();
    let addr = addrs.next().unwrap();
    //    let addr: SocketAddr = addr.as_str().to_socket_addrs()?;
    let count: usize = match args().nth(2) {
        Some(x) => x.parse()?,
        None => 100000,
    };
    println!("Sending {} lines to {}", count, addr);
    for _ in 1..count {
        let line = random_line(&mut rng);
        socket
            .send_to(&line.as_bytes(), &addr)
            .expect("failed to send message");
    }
    Ok(())
}
