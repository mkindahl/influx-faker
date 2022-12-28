use fake::faker::lorem::en::Word;
use fake::Fake;
use fake::{Dummy, Faker};
use rand::Rng;
use std::fmt;

pub struct Swap {
    host: String,
    free: u32,
    total: u32,
    used: u32,
    used_percent: f32,
    pub timestamp: u128,
}

impl fmt::Display for Swap {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            f,
            "swap,host={} free={}i,total={}i,used={}i,used_percent={} {}",
            self.host, self.free, self.total, self.used, self.used_percent, self.timestamp
        )
    }
}

impl Dummy<Faker> for Swap {
    fn dummy_with_rng<R: Rng + ?Sized>(_: &Faker, rng: &mut R) -> Self {
        let total: u32 = Faker.fake_with_rng(rng);
        let used: u32 = (0..total).fake_with_rng(rng);

        Swap {
            host: Word().fake_with_rng(rng),
            used: used,
            free: total - used,
            total: total,
            used_percent: used as f32 / total as f32,
            timestamp: Faker.fake_with_rng(rng),
        }
    }
}
