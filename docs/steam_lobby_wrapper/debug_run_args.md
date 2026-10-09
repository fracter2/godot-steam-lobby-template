
These are the run-args you can use with the "Debug / Customize Run Instances" dialogue

TODO ADD FROM OTHER PROJ

example setup
1: --no-steam --init-enet-lobby host 127.0.0.1 12345 P0_CYAN_host --logcolor CYAN --winpos-tile 0 --winpos-scale 50
2: --no-steam --init-enet-lobby client 127.0.0.1 12345 P1_YELLOW --logcolor YELLOW --winpos-tile 1 --winpos-scale 50
3: --no-steam --init-enet-lobby client 127.0.0.1 12345 P2_RED --logcolor RED --winpos-tile 2 --winpos-scale 50
2: --no-steam --init-enet-lobby client 127.0.0.1 12345 P3_ORANGE --logcolor ORANGE --winpos-tile 3 --winpos-scale 50
5: --no-steam --init-enet-lobby client 127.0.0.1 12345 P4_SALMON --logcolor SALMON --winpos-tile 4 --winpos-scale 50


Here are some launch args manually pasted
"--no-steam"
"-init-enet-lobby" - Requires 4 args, ex: "-init-enet-lobby=ishost=ip=port=username"
"+connect_lobby" - Only for steam lobbies
"-logcolor colorstr"
"-winpos-tile i"
"-winpos x y"
"-winpos-scale x ?y" - y is optional
