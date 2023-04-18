// Copyright 2023 XXIV
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
pub const BUFFER_INIT = @import("std").mem.zeroInit(buffer, .{ null, @as(c_int, 0), @as(c_int, 0) });

pub const buffer = extern struct {
    data: [*c]u8,
    len: usize,
    cap: usize,
};

pub const list_head = extern struct {
    blink: [*c]list_head,
    flink: [*c]list_head,
};


pub const nbt_status = enum(c_int) {
    OK   =  0,
    ERR  = -1,
    EMEM = -2,
    EIO  = -3,
    EZ   = -4
};

pub const nbt_type = enum(c_uint) {
    INVALID    = 0,
    BYTE       = 1,
    SHORT      = 2,
    INT        = 3,
    LONG       = 4,
    FLOAT      = 5,
    DOUBLE     = 6,
    BYTE_ARRAY = 7,
    STRING     = 8,
    LIST       = 9,
    COMPOUND   = 10,
    INT_ARRAY  = 11,
    LONG_ARRAY = 12
};

pub const nbt_compression_strategy = enum(c_uint) {
    GZIP,
    INFLATE
};

pub const nbt_byte_array = extern struct {
    data: [*c]u8,
    length: i32,
};

pub const nbt_int_array = extern struct {
    data: [*c]i32,
    length: i32,
};

pub const nbt_long_array = extern struct {
    data: [*c]i64,
    length: i32,
};

pub const nbt_list = extern struct {
    data: [*c]nbt_node,
    entry: list_head,
};

pub const nbt_node = extern struct {
    type: nbt_type,
    name: [*c]u8,
    payload: extern union {
        tag_byte: i8,
        tag_short: i16,
        tag_int: i32,
        tag_long: i64,
        tag_float: f32,
        tag_double: f64,
        tag_byte_array: nbt_byte_array,
        tag_int_array: nbt_int_array,
        tag_long_array: nbt_long_array,
        tag_string: [*c]u8,
        tag_list: [*c]nbt_list,
        tag_compound: [*c]nbt_list,
    },
};

pub const nbt_visitor_t = ?fn ([*c]nbt_node, ?*anyopaque) callconv(.C) bool;
pub const nbt_predicate_t = ?fn ([*c]const nbt_node, ?*anyopaque) callconv(.C) bool;

pub extern "C" fn nbt_parse_file(fp: [*c]@import("std").c.FILE) [*c]nbt_node;
pub extern "C" fn nbt_parse_path(filename: [*c]const u8) [*c]nbt_node;
pub extern "C" fn nbt_parse_compressed(chunk_start: ?*const anyopaque, length: usize) [*c]nbt_node;
pub extern "C" fn nbt_dump_file(tree: [*c]const nbt_node, fp: [*c]@import("std").c.FILE, nbt_compression_strategy) nbt_status;
pub extern "C" fn nbt_dump_compressed(tree: [*c]const nbt_node, nbt_compression_strategy) buffer;
pub extern "C" fn nbt_parse(memory: ?*const anyopaque, length: usize) [*c]nbt_node;
pub extern "C" fn nbt_dump_ascii(tree: [*c]const nbt_node) [*c]u8;
pub extern "C" fn nbt_dump_binary(tree: [*c]const nbt_node) buffer;
pub extern "C" fn nbt_clone([*c]nbt_node) [*c]nbt_node;
pub extern "C" fn nbt_free([*c]nbt_node) void;
pub extern "C" fn nbt_free_list([*c]nbt_list) void;
pub extern "C" fn nbt_map(tree: [*c]nbt_node, nbt_visitor_t, aux: ?*anyopaque) bool;
pub extern "C" fn nbt_filter(tree: [*c]const nbt_node, nbt_predicate_t, aux: ?*anyopaque) [*c]nbt_node;
pub extern "C" fn nbt_filter_inplace(tree: [*c]nbt_node, nbt_predicate_t, aux: ?*anyopaque) [*c]nbt_node;
pub extern "C" fn nbt_find(tree: [*c]nbt_node, nbt_predicate_t, aux: ?*anyopaque) [*c]nbt_node;
pub extern "C" fn nbt_find_by_name(tree: [*c]nbt_node, name: [*c]const u8) [*c]nbt_node;
pub extern "C" fn nbt_find_by_path(tree: [*c]nbt_node, path: [*c]const u8) [*c]nbt_node;
pub extern "C" fn nbt_size(tree: [*c]const nbt_node) usize;
pub extern "C" fn nbt_list_item(list: [*c]nbt_node, n: c_int) [*c]nbt_node;
pub extern "C" fn nbt_eq(noalias a: [*c]const nbt_node, noalias b: [*c]const nbt_node) bool;
pub extern "C" fn nbt_type_to_string(nbt_type) [*c]const u8;
pub extern "C" fn nbt_error_to_string(nbt_status) [*c]const u8;
pub extern "C" fn buffer_free(b: [*c]buffer) void;
pub extern "C" fn buffer_reserve(b: [*c]buffer, reserved_amount: usize) c_int;
pub extern "C" fn buffer_append(b: [*c]buffer, data: ?*const anyopaque, n: usize) c_int;

pub fn list_add_head(noalias arg_new_element: [*c]list_head, noalias arg_head: [*c]list_head) callconv(.C) [*c]list_head {
    var new_element = arg_new_element;
    var head = arg_head;
    new_element.*.flink = head.*.flink;
    new_element.*.blink = head;
    new_element.*.flink.*.blink = new_element;
    new_element.*.blink.*.flink = new_element;
    return head;
}

pub fn list_add_tail(noalias arg_new_element: [*c]list_head, noalias arg_head: [*c]list_head) callconv(.C) [*c]list_head {
    var new_element = arg_new_element;
    var head = arg_head;
    new_element.*.flink = head;
    new_element.*.blink = head.*.blink;
    new_element.*.flink.*.blink = new_element;
    new_element.*.blink.*.flink = new_element;
    return head;
}

pub fn list_del(arg_loc: [*c]list_head) callconv(.C) void {
    var loc = arg_loc;
    loc.*.flink.*.blink = loc.*.blink;
    loc.*.blink.*.flink = loc.*.flink;
    loc.*.flink = null;
    loc.*.blink = null;
}

pub fn list_length(arg_head: [*c]const list_head) callconv(.C) usize {
    var head = arg_head;
    var cursor: [*c]const list_head = undefined;
    var accum: usize = 0;
    {
        cursor = head.*.flink;
        while (cursor != head) : (cursor = cursor.*.flink) {
            accum +%= 1;
        }
    }
    return accum;
}

pub inline fn list_empty(head: [*c]const list_head) bool {
    return head.*.flink == head;
}
