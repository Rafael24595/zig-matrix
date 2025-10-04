const std = @import("std");

pub const AllocatorTracer = struct {
    base: *std.mem.Allocator,
    bytes_in_use: usize,

    pub fn init(base: *std.mem.Allocator) AllocatorTracer {
        return AllocatorTracer{
            .base = base,
            .bytes_in_use = 0,
        };
    }

    pub fn allocator(self: *AllocatorTracer) std.mem.Allocator {
        return std.mem.Allocator{
            .ptr = self,
            .vtable = &std.mem.Allocator.VTable{
                .alloc = alloc_wrapper,
                .resize = resize_wrapper,
                .remap = remap_wrapper,
                .free = free_wrapper,
            },
        };
    }

    pub fn reset(self: *AllocatorTracer) void {
        self.bytes_in_use = 0;
    }

    pub fn alloc(self: *AllocatorTracer, len: usize, alignment: std.mem.Alignment, ret_addr: usize) ?[*]u8 {
        const result = self.base.rawAlloc(len, alignment, ret_addr);
        if (result != null) {
            self.bytes_in_use += len;
        }
        return result;
    }

    pub fn resize(self: *AllocatorTracer, memory: []u8, alignment: std.mem.Alignment, new_len: usize, ret_addr: usize) bool {
        const old_len = memory.len;
        const result = self.base.rawResize(memory, alignment, new_len, ret_addr);
        if (result) {
            if (new_len > old_len) {
                self.bytes_in_use += new_len - old_len;
            } else {
                self.bytes_in_use -= old_len - new_len;
            }
        }
        return result;
    }

    pub fn remap(self: *AllocatorTracer, memory: []u8, alignment: std.mem.Alignment, new_len: usize, ret_addr: usize) ?[*]u8 {
        const old_len = memory.len;
        const result = self.base.rawRemap(memory, alignment, new_len, ret_addr);
        if (result != null) {
            if (new_len > old_len) {
                self.bytes_in_use += new_len - old_len;
            } else {
                self.bytes_in_use -= old_len - new_len;
            }
        }
        return result;
    }

    pub fn free(self: *AllocatorTracer, memory: []u8, alignment: std.mem.Alignment, ret_addr: usize) void {
        self.bytes_in_use -= memory.len;
        self.base.rawFree(memory, alignment, ret_addr);
    }

    pub fn bytes(self: *AllocatorTracer) usize {
        return self.bytes_in_use;
    }
};

fn alloc_wrapper(self: *anyopaque, len: usize, alignment: std.mem.Alignment, ret_addr: usize) ?[*]u8 {
    const ca: *AllocatorTracer = @ptrCast(@alignCast(self));
    return ca.alloc(len, alignment, ret_addr);
}

fn resize_wrapper(self: *anyopaque, memory: []u8, alignment: std.mem.Alignment, new_len: usize, ret_addr: usize) bool {
    const ca: *AllocatorTracer = @ptrCast(@alignCast(self));
    return ca.resize(memory, alignment, new_len, ret_addr);
}

fn remap_wrapper(self: *anyopaque, memory: []u8, alignment: std.mem.Alignment, new_len: usize, ret_addr: usize) ?[*]u8 {
    const ca: *AllocatorTracer = @ptrCast(@alignCast(self));
    return ca.remap(memory, alignment, new_len, ret_addr);
}

fn free_wrapper(self: *anyopaque, memory: []u8, alignment: std.mem.Alignment, ret_addr: usize) void {
    const ca: *AllocatorTracer = @ptrCast(@alignCast(self));
    ca.free(memory, alignment, ret_addr);
}
