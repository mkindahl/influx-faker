use fake::faker::filesystem::raw::*;
use fake::faker::lorem::raw::*;
use fake::locales::EN;
use fake::Fake;
use fake::{Dummy, Faker};
use rand::Rng;
use std::fmt;

pub struct Disk {
    device: String,
    fstype: String,
    host: String,
    mode: String,
    path: String,
    free: u32,
    inodes_free: u32,
    inodes_total: u32,
    inodes_used: u32,
    total: u32,
    used: u32,
    used_percent: f32,
    timestamp: u64,
}

impl fmt::Display for Disk {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            f,
            "disk,device={},fstype={},host={},mode={},path={} free={}i,inodes_free={}i,inodes_total={}i,inodes_used={}i,total={}i,used={}i,used_percent={} {}",
            self.device, self.fstype, self.host, self.mode, self.path, self.free, self.inodes_free, self.inodes_total, self.inodes_used, self.total, self.used, self.used_percent, self.timestamp
        )
    }
}

impl Dummy<Faker> for Disk {
    fn dummy_with_rng<R: Rng + ?Sized>(_: &Faker, rng: &mut R) -> Self {
        let inodes_total: u32 = Faker.fake_with_rng(rng);
        let inodes_used: u32 = (0..inodes_total).fake_with_rng(rng);
        let total = Faker.fake::<u32>();
        let used = (0..total).fake_with_rng(rng);

        Disk {
            device: Word(EN).fake::<String>(),
            fstype: Word(EN).fake::<String>(),
            host: Word(EN).fake::<String>(),
            mode: Word(EN).fake::<String>(),
            path: FilePath(EN).fake::<String>(),
            inodes_free: inodes_total - inodes_used,
            inodes_total,
            inodes_used,
            total,
            used,
            free: total - used,
            used_percent: 100.0 * (used as f32 / total as f32),
            timestamp: Faker.fake::<u64>(),
        }
    }
}
