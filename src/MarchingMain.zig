const std = @import("std");
const stdout = std.debug;
const sdl = @import("SDLimport.zig");
const LoadTextureFromMem = @import("LoadResource.zig").LoadTextureFromMem;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
pub const allocator = gpa.allocator();
const pTexture = *sdl.SDL_Texture;
const noise3D = @import("Noise3D.zig").noise3D;

// Tiles
const pTiles = @embedFile("Marching8.png");

// Main parameters
const refreshrate = 40; // [ms]
const tilesize = 8;
const resolution = 3.0;
const threshold = 0.25;
const speed = 0.015;

// Calculated parameters
var prng: std.Random.DefaultPrng = undefined;
var canvasW: u32 = undefined;
var canvasH: u32 = undefined;
var matrixW: usize = undefined;
var matrixH: usize = undefined;
var matrixStride: usize = undefined;
var matrixTotal: usize = undefined;
var matrix: []bool = undefined;
var tileTextures: pTexture = undefined;
var tileRects: [16]sdl.SDL_Rect = undefined;
var factorX: f32 = undefined;
var factorY: f32 = undefined;

pub fn InitRandomizer() !void {
    var seed: u64 = undefined;
    try std.posix.getrandom(std.mem.asBytes(&seed));
    prng = std.Random.DefaultPrng.init(seed);
}

pub fn main() !void {
    // SDL Initialisation
    if (sdl.SDL_Init(sdl.SDL_INIT_TIMER | sdl.SDL_INIT_VIDEO) != 0) {
        stdout.print("SDL initialisation error: {s}\n", .{sdl.SDL_GetError()});
        return error.sdl_initialisationerror;
    }
    defer sdl.SDL_Quit();

    const window: *sdl.SDL_Window = sdl.SDL_CreateWindow(
        "SDL main window",
        0,
        0,
        800,
        600,
        sdl.SDL_WINDOW_FULLSCREEN_DESKTOP,
    ) orelse {
        stdout.print("SDL window creation failed: {s}\n", .{sdl.SDL_GetError()});
        return error.sdl_windowcreationfailed;
    };
    defer sdl.SDL_DestroyWindow(window);
    sdl.SDL_GetWindowSize(window, @ptrCast(&canvasW), @ptrCast(&canvasH));
    stdout.print("Window dimensions: {}x{}\n", .{ canvasW, canvasH });
    const renderer = sdl.SDL_CreateRenderer(window, -1, sdl.SDL_RENDERER_ACCELERATED) orelse {
        stdout.print("SDL renderer creation failed: {s}\n", .{sdl.SDL_GetError()});
        return error.sdl_renderercreationfailed;
    };
    defer sdl.SDL_DestroyRenderer(renderer);
    var rendererinfo: sdl.SDL_RendererInfo = undefined;
    _ = sdl.SDL_GetRendererInfo(renderer, &rendererinfo);
    stdout.print("Renderer info: {s}\n", .{rendererinfo.name});

    // Program initialisation
    try InitRandomizer();
    matrixW = @divFloor((canvasW + tilesize - 1), tilesize);
    matrixH = @divFloor((canvasH + tilesize - 1), tilesize);
    factorX = @as(f32, @floatFromInt(tilesize)) * resolution / @as(f32, @floatFromInt(canvasW));
    factorY = @as(f32, @floatFromInt(tilesize)) * resolution / @as(f32, @floatFromInt(canvasH));
    matrixStride = matrixW + 1;
    matrixTotal = (matrixW + 1) * (matrixH + 1);
    matrix = try allocator.alloc(bool, matrixTotal);
    defer allocator.free(matrix);

    // Canvas initialisation
    tileTextures = try LoadTextureFromMem(renderer, pTiles);
    defer sdl.SDL_DestroyTexture(tileTextures);
    for (0..16) |index| {
        tileRects[index] = sdl.SDL_Rect{
            .x = @intCast(tilesize * (index % 4)),
            .y = @intCast((tilesize * (index / 4))),
            .w = @intCast(tilesize),
            .h = @intCast(tilesize),
        };
    }
    _ = sdl.SDL_SetRenderDrawColor(renderer, 210, 210, 210, 255);

    // Hide mouse
    _ = sdl.SDL_ShowCursor(sdl.SDL_DISABLE);

    // Prepare program loop
    var timer = try std.time.Timer.start();
    var stoploop = false;
    var event: sdl.SDL_Event = undefined;
    var z: f32 = 0.0;
    var maximum: f32 = -1000.0;
    var minimum: f32 = 1000.0;

    //Main loop
    while (!stoploop) {
        // Loop refresh
        timer.reset();
        sdl.SDL_RenderPresent(renderer);
        // Here come the drawing and update
        z += speed;
        for (0..matrixW + 1) |xi| {
            for (0..matrixH + 1) |yi| {
                const index = yi * matrixStride + xi;
                const x: f32 = @as(f32, @floatFromInt(xi)) * factorX;
                const y: f32 = @as(f32, @floatFromInt(yi)) * factorY;
                const n: f32 = noise3D(f32, x, y, z);
                matrix[index] = n > threshold;
                maximum = @max(maximum, n);
                minimum = @min(minimum, n);
            }
        }
        _ = sdl.SDL_RenderClear(renderer);
        for (0..matrixH) |y| {
            for (0..matrixW) |x| {
                const index: usize = y * matrixStride + x;
                var res: usize = 0;
                if (matrix[index]) res += 1;
                if (matrix[index + 1]) res += 2;
                if (matrix[index + matrixStride + 1]) res += 4;
                if (matrix[index + matrixStride]) res += 8;
                _ = sdl.SDL_RenderCopy(renderer, tileTextures, &tileRects[res], @constCast(&sdl.SDL_Rect{
                    .x = @intCast(x * tilesize),
                    .y = @intCast(y * tilesize),
                    .w = @intCast(tilesize),
                    .h = @intCast((tilesize)),
                }));
            }
        }
        // Here come the user interactions
        while (sdl.SDL_PollEvent(&event) != 0) {
            if (event.type == sdl.SDL_KEYDOWN) stoploop = true;
        }
        // Here come the timer instructions to wait for next frame
        const lap: u32 = @intCast(timer.read() / 1_000_000);
        if (lap < refreshrate) sdl.SDL_Delay(refreshrate - lap);
    }
}
