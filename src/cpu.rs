use fake::faker::lorem::en::Word;
use fake::faker::number::en::NumberWithFormat;
use fake::Fake;
use fake::{Dummy, Faker};
use rand::Rng;
use std::fmt;

pub struct Cpu {
    cpu: String,
    host: String,
    usage_idle: f32,
    usage_iowait: f32,
    usage_nice: f32,
    usage_system: f32,
    usage_user: f32,
    timestamp: u64,
}

impl Dummy<Faker> for Cpu {
    fn dummy_with_rng<R: Rng + ?Sized>(_: &Faker, rng: &mut R) -> Self {
        Cpu {
            cpu: NumberWithFormat("cpu#").fake_with_rng(rng),
            usage_user: (0.0..10.0).fake_with_rng(rng),
            usage_idle: (0.0..10.0).fake_with_rng(rng),
            usage_nice: (0.0..10.0).fake_with_rng(rng),
            usage_iowait: (0.0..10.0).fake_with_rng(rng),
            usage_system: (0.0..10.0).fake_with_rng(rng),
            host: Word().fake_with_rng(rng),
            timestamp: Faker.fake_with_rng(rng),
        }
    }
}

impl fmt::Display for Cpu {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        writeln!(
            f,
            "cpu,cpu={},host={} usage_idle={},usage_iowait={},usage_nice={},usage_system={},usage_user={} {}",
            self.cpu, self.host, self.usage_idle, self.usage_iowait, self.usage_nice, self.usage_system, self.usage_user, self.timestamp
        )
    }
}
