use fake::faker::filesystem::raw::*;
use fake::faker::lorem::raw::*;
use fake::faker::number::raw::*;
use fake::locales::EN;
use fake::{Fake, Faker};
use rand::Rng;
use std::env::args;
use std::error::Error;
use std::net::SocketAddr;
use std::net::UdpSocket;

fn fake_swap() -> String {
    format!(
        "swap,host={} free={}i,total={}i,used={}i,used_percent={} {}",
        Word(EN).fake::<String>(),
        Faker.fake::<u32>(),
        Faker.fake::<u32>(),
        Faker.fake::<u32>(),
        (0.0..1.0).fake::<f32>(),
        Faker.fake::<u64>(),
    )
}

fn fake_cpu() -> String {
    format!("cpu,cpu={},host={} usage_idle={},usage_iowait={},usage_nice={},usage_system={},usage_user={} {}\n",
            NumberWithFormat(EN, "cpu#").fake::<String>(),
            Word(EN).fake::<String>(),
            (0.0..6.0).fake::<f32>(),
            (0.0..6.0).fake::<f32>(),
            (0.0..6.0).fake::<f32>(),
            (0.0..6.0).fake::<f32>(),
            (0.0..6.0).fake::<f32>(),
        Faker.fake::<u64>(),
    )
}

fn fake_diskio() -> String {
    format!(
        "diskio,host={},name={} io_time={}i,read_bytes={}i,write_bytes={}i {}\n",
        Word(EN).fake::<String>(),
        Word(EN).fake::<String>(),
        Faker.fake::<f32>(),
        Faker.fake::<u32>(),
        Faker.fake::<u32>(),
        Faker.fake::<u64>(),
    )
}

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
    let alt: Vec<fn() -> String> = vec![fake_swap, fake_diskio, fake_cpu, fake_disk];
    alt[rng.gen::<usize>() % alt.len()]()
}

fn main() -> Result<(), Box<dyn Error>> {
    let socket = UdpSocket::bind("0.0.0.0:0")?;
    let mut rng = rand::thread_rng();
    let addr: SocketAddr = args().nth(1).unwrap().parse()?;
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
