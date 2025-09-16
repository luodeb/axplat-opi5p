//! Memory allocator test module
//!
//! This module contains various tests for the memory allocator, including
//! basic allocation, deallocation, boundary condition tests, stress tests, etc.

use alloc::{boxed::Box, format, string::String, vec, vec::Vec};

/// Test result structure
#[derive(Debug, Clone)]
pub struct TestResult {
    pub name: &'static str,
    pub passed: bool,
    pub error_msg: Option<&'static str>,
}

impl TestResult {
    pub fn new(name: &'static str, passed: bool, error_msg: Option<&'static str>) -> Self {
        Self {
            name,
            passed,
            error_msg,
        }
    }
}

/// Memory allocator test suite
pub struct AllocatorTestSuite {
    results: Vec<TestResult>,
}

impl AllocatorTestSuite {
    pub fn new() -> Self {
        Self {
            results: Vec::new(),
        }
    }

    /// Run all tests
    pub fn run_all_tests(&mut self) {
        info!("Start testing allocator...");

        self.test_basic_allocation();
        self.test_vec_operations();
        self.test_box_allocation();
        self.test_string_allocation();
        self.test_large_allocation();
        self.test_many_small_allocations();
        self.test_zero_size_allocation();

        self.print_results();
    }

    /// Basic allocation test
    fn test_basic_allocation(&mut self) {
        let test_name = "Basic allocation test";
        info!("Running test: {}", test_name);

        let mut passed = true;
        let mut error_msg = None;

        // Test basic Vec allocation
        let mut vec = Vec::new();
        vec.push(42u32);
        vec.push(100u32);

        if vec.len() != 2 || vec[0] != 42 || vec[1] != 100 {
            passed = false;
            error_msg = Some("Basic Vec operation failed");
        }

        if passed {
            // Test expansion
            for i in 0..100 {
                vec.push(i);
            }
            if vec.len() != 102 {
                passed = false;
                error_msg = Some("Vec expansion failed");
            }
        }

        self.results
            .push(TestResult::new(test_name, passed, error_msg));
    }

    /// Vec operations test
    fn test_vec_operations(&mut self) {
        let test_name = "Vec operations test";
        info!("Running test: {}", test_name);

        let mut passed = true;
        let mut error_msg = None;

        let mut vec = Vec::with_capacity(10);

        // Test pre-allocated capacity
        if vec.capacity() < 10 {
            passed = false;
            error_msg = Some("Vec capacity allocation failed");
        }

        if passed {
            // Fill data
            for i in 0..20 {
                vec.push(i * 2);
            }

            // Test access
            if vec[5] != 10 || vec[19] != 38 {
                passed = false;
                error_msg = Some("Vec data access failed");
            }

            if passed {
                // Test pop
                let last = vec.pop();
                if last != Some(38) || vec.len() != 19 {
                    passed = false;
                    error_msg = Some("Vec pop operation failed");
                }

                if passed {
                    // Test clear
                    vec.clear();
                    if !vec.is_empty() {
                        passed = false;
                        error_msg = Some("Vec clear operation failed");
                    }
                }
            }
        }

        self.results
            .push(TestResult::new(test_name, passed, error_msg));
    }

    /// Box allocation test
    fn test_box_allocation(&mut self) {
        let test_name = "Box allocation test";
        info!("Running test: {}", test_name);

        let mut passed = true;
        let mut error_msg = None;

        // Test basic Box allocation
        let boxed_int = Box::new(42i32);
        if *boxed_int != 42 {
            passed = false;
            error_msg = Some("Basic Box allocation failed");
        }

        if passed {
            // Test large object Box allocation
            let large_array = Box::new([0u8; 1024]);
            if large_array.len() != 1024 {
                passed = false;
                error_msg = Some("Large object Box allocation failed");
            }

            if passed {
                // Test Box<Vec>
                let boxed_vec = Box::new(vec![1, 2, 3, 4, 5]);
                if boxed_vec.len() != 5 || boxed_vec[2] != 3 {
                    passed = false;
                    error_msg = Some("Box<Vec> allocation failed");
                }
            }
        }

        self.results
            .push(TestResult::new(test_name, passed, error_msg));
    }

    /// String allocation test
    fn test_string_allocation(&mut self) {
        let test_name = "String allocation test";
        info!("Running test: {}", test_name);

        let mut passed = true;
        let mut error_msg = None;

        // Test String creation
        let mut s = String::new();
        s.push_str("Hello, ");
        s.push_str("World!");

        if s != "Hello, World!" || s.len() != 13 {
            passed = false;
            error_msg = Some("String basic operation failed");
        }

        if passed {
            // Test String expansion
            for i in 0..10 {
                s.push_str(&format!("{}", i));
            }

            if s.len() <= 13 {
                passed = false;
                error_msg = Some("String expansion failed");
            }
        }

        self.results
            .push(TestResult::new(test_name, passed, error_msg));
    }

    /// Large memory allocation test
    fn test_large_allocation(&mut self) {
        let test_name = "Large memory allocation test";
        info!("Running test: {}", test_name);

        let mut passed = true;
        let mut error_msg = None;

        // Try to allocate 512KB of memory (reduced size to fit heap limits)
        let large_vec: Vec<u8> = vec![0; 512 * 1024];
        if large_vec.len() != 512 * 1024 {
            passed = false;
            error_msg = Some("Large memory allocation failed");
        }

        if passed {
            // Write some data to verify memory is usable
            let mut mutable_vec = large_vec;
            mutable_vec[0] = 0xAA;
            mutable_vec[512 * 1024 - 1] = 0xBB;

            if mutable_vec[0] != 0xAA || mutable_vec[512 * 1024 - 1] != 0xBB {
                passed = false;
                error_msg = Some("Large memory read/write failed");
            }
        }

        self.results
            .push(TestResult::new(test_name, passed, error_msg));
    }

    /// Multiple small memory allocations test
    fn test_many_small_allocations(&mut self) {
        let test_name = "Multiple small memory allocations test";
        info!("Running test: {}", test_name);

        let mut passed = true;
        let mut error_msg = None;

        let mut boxes = Vec::new();

        // Allocate 1000 small objects
        for i in 0..1000 {
            let boxed = Box::new(i);
            boxes.push(boxed);
        }

        // Verify data correctness
        for (i, boxed) in boxes.iter().enumerate() {
            if **boxed != i {
                passed = false;
                error_msg = Some("Small memory allocation data error");
                break;
            }
        }

        if passed && boxes.len() != 1000 {
            passed = false;
            error_msg = Some("Small memory allocation count error");
        }

        self.results
            .push(TestResult::new(test_name, passed, error_msg));
    }

    /// Zero-size allocation test
    fn test_zero_size_allocation(&mut self) {
        let test_name = "Zero-size allocation test";
        info!("Running test: {}", test_name);

        let mut passed = true;
        let mut error_msg = None;

        // Test zero-size Vec
        let empty_vec: Vec<u32> = Vec::new();
        if !empty_vec.is_empty() {
            passed = false;
            error_msg = Some("Zero-size Vec failed");
        }

        if passed {
            // Test empty string
            let empty_string = String::new();
            if !empty_string.is_empty() {
                passed = false;
                error_msg = Some("Empty string failed");
            }

            if passed {
                // Test zero-size array
                let zero_array: Vec<u8> = vec![];
                if !zero_array.is_empty() {
                    passed = false;
                    error_msg = Some("Zero-size array failed");
                }
            }
        }

        self.results
            .push(TestResult::new(test_name, passed, error_msg));
    }

    /// Print test results
    fn print_results(&self) {
        info!("=== Memory Allocator Test Results ===");

        let mut passed_count = 0;
        let total_count = self.results.len();

        for result in &self.results {
            if result.passed {
                info!("✓ {}", result.name);
                passed_count += 1;
            } else {
                error!(
                    "✗ {} - {}",
                    result.name,
                    result.error_msg.unwrap_or("Unknown error")
                );
            }
        }

        info!("Test completed: {}/{} passed", passed_count, total_count);

        if passed_count == total_count {
            info!("🎉 All tests passed! Memory allocator is working correctly.");
        } else {
            warn!(
                "⚠️  {} tests failed, please check the memory allocator implementation.",
                total_count - passed_count
            );
        }
    }
}

/// Convenient function to run memory allocator tests
pub fn run_allocator_tests() {
    let mut test_suite = AllocatorTestSuite::new();
    test_suite.run_all_tests();
}
