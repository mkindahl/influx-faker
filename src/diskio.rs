use fake::faker::lorem::en::Word;
use fake::Fake;
use fake::{Dummy, Faker};
use rand::Rng;
use std::fmt;

pub struct DiskIO {
    host: String,
    name: String,
    io_time: f32,
    read_bytes: u32,
    write_bytes: u32,
    pub timestamp: u128,
}

impl fmt::Display for DiskIO {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            f,
            "diskio,host={},name={} io_time={}i,read_bytes={}i,write_bytes={}i {}",
            self.host, self.name, self.io_time, self.read_bytes, self.write_bytes, self.timestamp
        )
    }
}

impl Dummy<Faker> for DiskIO {
    fn dummy_with_rng<R: Rng + ?Sized>(_: &Faker, rng: &mut R) -> Self {
        DiskIO {
            host: Word().fake_with_rng(rng),
            name: Word().fake_with_rng(rng),
            io_time: Faker.fake_with_rng(rng),
            read_bytes: Faker.fake_with_rng(rng),
            write_bytes: Faker.fake_with_rng(rng),
            timestamp: Faker.fake_with_rng(rng),
        }
    }
}
