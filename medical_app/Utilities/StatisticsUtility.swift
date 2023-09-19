import Darwin

struct StatisticsUtility {
    
    static func reportMemory() -> String {
        var taskInfo = task_vm_info_data_t()
            var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size) / 4
            let result: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0.withMemoryRebound(to: Int32.self, capacity: 1) { zeroPtr in
                    zeroPtr
                }, &count)
            }
            
            if result != KERN_SUCCESS {
                return "N/A"
            }
            
            return String(format: "%.2f MB", Float(taskInfo.resident_size) / 1024.0 / 1024.0)
        }

    static func cpuUsage() -> String {
        var threadInfo = thread_basic_info()
        var threadInfoCount = mach_msg_type_number_t(MemoryLayout<thread_basic_info_data_t>.size / MemoryLayout<integer_t>.stride)
            
        let result: kern_return_t = withUnsafeMutablePointer(to: &threadInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                thread_info(mach_thread_self(), thread_flavor_t(THREAD_BASIC_INFO), $0, &threadInfoCount)
            }
        }

        if result == KERN_SUCCESS {
            let userTime = Double(threadInfo.user_time.seconds) + Double(threadInfo.user_time.microseconds) / 1_000_000.0
            let systemTime = Double(threadInfo.system_time.seconds) + Double(threadInfo.system_time.microseconds) / 1_000_000.0
            let totalTime = userTime + systemTime
            return String(format: "%.2f s", totalTime)
        } else {
            return "N/A"
        }
    }
}

