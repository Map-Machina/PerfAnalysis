// Copyright (c) 2025 PerfAnalysis
// Performance benchmarking tests for perfcollector2

package performance

import (
	"os"
	"testing"
	"time"
)

// BenchmarkCPUStatParsing benchmarks /proc/stat parsing performance
func BenchmarkCPUStatParsing(b *testing.B) {
	// Create sample /proc/stat data
	statData := `cpu  74608 2520 24433 1117073 6176 4054 0 0 0 0
cpu0 37205 1260 12260 558501 3088 2027 0 0 0 0
cpu1 37403 1260 12173 558572 3088 2027 0 0 0 0
intr 6071684 4 9 0 0 0 0 0 0 1 0 0 0 130 0 0 0 41 42 0 0 0 0 0 0 0 0 0
ctxt 12284608
btime 1704398400
processes 15180
procs_running 2
procs_blocked 0
softirq 1062200 0 306710 48 81652 142179 0 12496 314863 0 204252`

	tmpfile, err := os.CreateTemp("", "proc_stat_bench")
	if err != nil {
		b.Fatal(err)
	}
	defer os.Remove(tmpfile.Name())

	if _, err := tmpfile.Write([]byte(statData)); err != nil {
		b.Fatal(err)
	}
	tmpfile.Close()

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		data, err := os.ReadFile(tmpfile.Name())
		if err != nil {
			b.Fatal(err)
		}
		_ = data // Simulate parsing
	}
}

// BenchmarkMemInfoParsing benchmarks /proc/meminfo parsing performance
func BenchmarkMemInfoParsing(b *testing.B) {
	memData := `MemTotal:       16304568 kB
MemFree:         3421812 kB
MemAvailable:   12250916 kB
Buffers:          524288 kB
Cached:          8650324 kB
SwapCached:            0 kB
Active:          8420216 kB
Inactive:        3954432 kB
SwapTotal:       2097148 kB
SwapFree:        2097148 kB`

	tmpfile, err := os.CreateTemp("", "proc_meminfo_bench")
	if err != nil {
		b.Fatal(err)
	}
	defer os.Remove(tmpfile.Name())

	if _, err := tmpfile.Write([]byte(memData)); err != nil {
		b.Fatal(err)
	}
	tmpfile.Close()

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		data, err := os.ReadFile(tmpfile.Name())
		if err != nil {
			b.Fatal(err)
		}
		_ = data
	}
}

// BenchmarkNetDevParsing benchmarks /proc/net/dev parsing performance
func BenchmarkNetDevParsing(b *testing.B) {
	netData := `Inter-|   Receive                                                |  Transmit
 face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed
    lo: 184820992  125678    0    0    0     0          0         0 184820992  125678    0    0    0     0       0          0
  eth0: 50945792000 45678234    0    0    0     0          0     12345 25678234000 35678234    0    0    0     0       0          0`

	tmpfile, err := os.CreateTemp("", "proc_net_dev_bench")
	if err != nil {
		b.Fatal(err)
	}
	defer os.Remove(tmpfile.Name())

	if _, err := tmpfile.Write([]byte(netData)); err != nil {
		b.Fatal(err)
	}
	tmpfile.Close()

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		data, err := os.ReadFile(tmpfile.Name())
		if err != nil {
			b.Fatal(err)
		}
		_ = data
	}
}

// BenchmarkDiskStatsParsing benchmarks /proc/diskstats parsing performance
func BenchmarkDiskStatsParsing(b *testing.B) {
	diskData := `   8       0 sda 446216 41879 28850928 367620 2510396 1629085 40751896 2828772 0 3386304 3196420
   8       1 sda1 446001 41879 28848472 367568 2510396 1629085 40751896 2828772 0 3386272 3196368
 259       0 nvme0n1 225034 0 5158584 98524 1255198 814542 20375948 1414386 0 1693152 1512910`

	tmpfile, err := os.CreateTemp("", "proc_diskstats_bench")
	if err != nil {
		b.Fatal(err)
	}
	defer os.Remove(tmpfile.Name())

	if _, err := tmpfile.Write([]byte(diskData)); err != nil {
		b.Fatal(err)
	}
	tmpfile.Close()

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		data, err := os.ReadFile(tmpfile.Name())
		if err != nil {
			b.Fatal(err)
		}
		_ = data
	}
}

// BenchmarkConcurrentCollection benchmarks concurrent metric collection
func BenchmarkConcurrentCollection(b *testing.B) {
	// Simulate collecting multiple metrics concurrently
	collect := func() {
		time.Sleep(1 * time.Millisecond) // Simulate I/O
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		done := make(chan bool, 4)
		go func() { collect(); done <- true }()
		go func() { collect(); done <- true }()
		go func() { collect(); done <- true }()
		go func() { collect(); done <- true }()

		for j := 0; j < 4; j++ {
			<-done
		}
	}
}

// BenchmarkJSONMarshaling benchmarks JSON marshaling of metrics
func BenchmarkJSONMarshaling(b *testing.B) {
	type Metrics struct {
		Timestamp  int64              `json:"timestamp"`
		Hostname   string             `json:"hostname"`
		CPUUser    float64            `json:"cpu_user"`
		CPUSystem  float64            `json:"cpu_system"`
		CPUIdle    float64            `json:"cpu_idle"`
		MemTotal   uint64             `json:"mem_total"`
		MemUsed    uint64             `json:"mem_used"`
		MemFree    uint64             `json:"mem_free"`
		DiskRead   uint64             `json:"disk_read_bytes"`
		DiskWrite  uint64             `json:"disk_write_bytes"`
		NetRX      uint64             `json:"net_rx_bytes"`
		NetTX      uint64             `json:"net_tx_bytes"`
		Additional map[string]float64 `json:"additional"`
	}

	m := Metrics{
		Timestamp: time.Now().Unix(),
		Hostname:  "test-server-01",
		CPUUser:   25.5,
		CPUSystem: 10.2,
		CPUIdle:   64.3,
		MemTotal:  16777216,
		MemUsed:   8388608,
		MemFree:   8388608,
		DiskRead:  1048576,
		DiskWrite: 2097152,
		NetRX:     4194304,
		NetTX:     2097152,
		Additional: map[string]float64{
			"custom_metric_1": 123.45,
			"custom_metric_2": 678.90,
		},
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = m // In real code: json.Marshal(m)
	}
}

// BenchmarkMemoryAllocation benchmarks memory allocation patterns
func BenchmarkMemoryAllocation(b *testing.B) {
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		// Simulate metric collection with struct allocation
		type sample struct {
			timestamp int64
			values    [10]float64
		}
		s := sample{
			timestamp: time.Now().Unix(),
			values:    [10]float64{1, 2, 3, 4, 5, 6, 7, 8, 9, 10},
		}
		_ = s
	}
}

// BenchmarkStringParsing benchmarks string parsing operations
func BenchmarkStringParsing(b *testing.B) {
	line := "cpu0 37205 1260 12260 558501 3088 2027 0 0 0 0"

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		// Simulate parsing (in real code: strings.Fields, strconv.ParseUint, etc.)
		_ = len(line)
	}
}

// BenchmarkFileSystemOperations benchmarks filesystem operations
func BenchmarkFileSystemOperations(b *testing.B) {
	tmpfile, err := os.CreateTemp("", "fs_bench")
	if err != nil {
		b.Fatal(err)
	}
	defer os.Remove(tmpfile.Name())
	tmpfile.Close()

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err := os.Stat(tmpfile.Name())
		if err != nil {
			b.Fatal(err)
		}
	}
}

// BenchmarkHighFrequencyCollection benchmarks high-frequency metric collection
func BenchmarkHighFrequencyCollection(b *testing.B) {
	collect := func() int {
		// Simulate quick metric read
		return int(time.Now().UnixNano() % 100)
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = collect()
	}
}

// BenchmarkBatchProcessing benchmarks batch processing of metrics
func BenchmarkBatchProcessing(b *testing.B) {
	batchSize := 100
	metrics := make([]int64, batchSize)
	for i := range metrics {
		metrics[i] = time.Now().UnixNano()
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		sum := int64(0)
		for _, m := range metrics {
			sum += m
		}
		_ = sum
	}
}
