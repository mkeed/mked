//41 01 //i32.const 1
//21 02 //local.set 2
//03 40 //loop
//  02 40//loop
//    20 02//local.get 2
//    20 01//local.get 1
//    4a i32.gt_s
//    0d 00 //br_if
//    20 02 //local.get 2
//    20 00 //local.get 0
//    6c
//    21 02
//    0c 01 br 1
//    0b
//  0b
//20 02
//0b

const Instr = enum(u8) {
    //5.4.1 Control Instructions
    unreach = 0,
    nop = 1,
    block = 2,
    loop = 3,
    @"if" = 4,
    @"else" = 5,
    br = 0x0c,
    br_if = 0x0d,
    br_table = 0x0e,
    @"return" = 0x0f,
    call = 0x10,
    call_indirect = 0x11,

    //5.4.2 Reference Instructions

    ref_null = 0xD0,
    ref_is_null = 0xD1,
    ref_func = 0xD2,

    //5.4.3 Parametric Instructions

    drop = 0x1A,
    select = 0x1B,
    select_t = 0x1C,

    //5.4.4 Variable Instructions

    local_get = 0x20,
    local_set = 0x21,
    local_tee = 0x22,
    global_get = 0x23,
    gloval_set = 0x24,

    //5.4.5 Table Instructions
    table_get = 0x25,
    table_set = 0x26,

    //5.4.6 Memory Instructions
    i32_load = 0x28,
    i64_load = 0x29,
    f32_load = 0x2A,
    f64_load = 0x2B,
    i32_load_8_s = 0x2C,
    i32_load_8_u = 0x2D,
    i32_load_16_s = 0x2E,
    i32_load_16_u = 0x2F,

    i64_load_8_s = 0x30,
    i64_load_8_u = 0x31,
    i64_load_16_s = 0x32,
    i64_load_16_u = 0x33,
    i64_load_32_s = 0x34,
    i64_load_32_u = 0x35,

    i32_store = 0x36,
    i64_store = 0x37,
    f32_store = 0x38,
    f64_store = 0x39,
    i32_store_8 = 0x3A,
    i32_store_16 = 0x3B,
    i64_store_8 = 0x3C,
    i64_store_16 = 0x3D,
    i64_store_32 = 0x3E,

    memory_size = 0x3F,
    memory_grow = 0x40,

    //5.4.7 Numeric Instructions
    i32_const = 0x41,
    i64_const = 0x42,
    f32_const = 0x43,
    f64_const = 0x44,

    variable_length = 0xFC,
};
