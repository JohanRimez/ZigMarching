const std = @import("std");
const stdout = std.debug;
const sdl = @import("SDLimport.zig");

pub fn LoadTextureFromMem(renderer: *sdl.SDL_Renderer, pTexture: [:0]const u8) !*sdl.SDL_Texture {
    const rwOps = sdl.SDL_RWFromConstMem(@ptrCast(pTexture), @intCast(pTexture.len));
    if (rwOps == null) {
        stdout.print("Error reading resource: {s}\n", .{sdl.SDL_GetError()});
        return error.sdlError;
    }
    const texture = sdl.IMG_LoadTexture_RW(renderer, rwOps, 1) orelse {
        stdout.print("Error reading resource: {s}\n", .{sdl.SDL_GetError()});
        return error.sdlError;
    };
    return texture;
}