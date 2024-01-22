col_positions = [
    [ 3.2, [-37.6,  -8.5, 7.2]],
    [ 3.2, [  -20,  -7.7, 5.3]],
    [   0, [    0,     0,   0]],
    [-2.1, [ 19.1,    -6, 4.5]],
    [-5.8, [ 39.6, -15.9,  12]],
    [-6.2, [ 56.9, -22.6,  14]],
];
key_rotations = [
    [[ -9, 0, 0, 0], [-9, 0, 0, 0], [-9, 0, 0, 0], [-9,   0, 0, 0], [-9,  0, 0, 0], [  -9,   0, 0, 0]],
    [[  0, 8, 0, 0], [ 0, 5, 0, 0], [ 0, 0, 0, 0], [ 0, -10, 0, 0], [ 0, -5, 0, 0], [-2.5, -10, 0, 0]],
    [[  9, 0, 0, 0], [ 9, 0, 0, 0], [ 9, 0, 0, 0], [ 9,   0, 0, 0], [ 9,  0, 0, 0], [   9,   0, 0, 0]],
];

thumb_offset = [-14, -30, 10];
thumb_rotation = [-8, -0, -16];

col_positions_thumb = [
    [ 5, [-1,  -8, 3.2]],
    [ 0, [19,  -2, 0]],
    [ 0, [41,  0, 8.2]],
];
key_rotations_thumb = [
    [[ 0, 20, 0, 0], [-3, 0, 0,   0], [0, -45, 0,   0]],
    [[15,  2, 0, 1], [25, 0, 0, 2.2], [0,   0, 0, 2.2]],
];

key_walls_thumb = [
    ".-----.",
    "|x x x|",
    "|     |",
    "|x x   ",
    ".---   ",
];

key_walls = [
    "    --------.",
    " x x x x x x|",
    "|           |",
    "|x x x x x x|",
    "|           |",
    "|x x x x x x|",
    ".-----------.",
];

grid_height = 5;
border_height = 5;
border_width = 3;
border_hskew = 2;
base_extra_height = 2;
angle = 30;
caps = false;

key_size = 13.85;
key_vmargin = 9;
key_height = 1.2;

insert_offset = 1.5;
insert_depth = 0.5;
insert_height = 2;

hpad_bot = 1;
vpad_bot = 1;
hpad_top = 1;
vpad_top = 1;

function key_rotations_overflow(rotations, col, row, cols, rows) =
    row >= 0 && row < rows && col >= 0 && col < cols
    ? rotations[row][col]
    : row >= 0 && row < rows
      ? rotations[row][col < 0 ? 0 : cols-1]
      : [0, 0, 0];

function col_positions_overflow(positions, homerow, rotations, col, cols) =
    col >= 0 && col < cols
    ? positions[col]
    : let(
        dir = col < 0 ? -1 : 1,
        index = col < 0 ? 0 : cols - 1,
        col_position = positions[index],
        rot = col_position[0],
        hoffset = dir * (key_size + border_width),
        angles = [
            cos(rotations[homerow][index][1]),
            sin(rot),
            -sin(rotations[homerow][index][1]),
        ],
        pos = col_position[1] + hoffset * angles
    ) [rot, pos];

function rot(x, y, cx, cy, a) =
    let(
        l = sqrt(pow(x - cx, 2) + pow(y - cy, 2)),
        b = a + acos((x - cx) / l)
    ) [cx + l * cos(b), cy + l * sin(b)];

function rotation_matrix(a) =
    [[cos(a[1]) * cos(a[2]), sin(a[0]) * sin(a[1]) * cos(a[2]) - cos(a[0]) * sin(a[2]),
                             cos(a[0]) * sin(a[1]) * cos(a[2]) + sin(a[0]) * sin(a[2])],
     [cos(a[1]) * sin(a[2]), sin(a[0]) * sin(a[1]) * sin(a[2]) + cos(a[0]) * cos(a[2]),
                             cos(a[0]) * sin(a[1]) * sin(a[2]) - sin(a[0]) * cos(a[2])],
     [           -sin(a[1]), sin(a[0]) * cos(a[1]),
                             cos(a[0]) * cos(a[1])]];

function slice(list, start, length) =
    [for (i=[start:length-1]) list[i]];

function project_down(positions) =
    [for (i=[0:len(positions)-1]) [positions[i][0], positions[i][1], 0]];

function grid_pos(positions, homerow, rotations, angle, col, row) =
    let (
        cols = len(positions),
        rows = len(rotations),
        dir = row >= homerow ? 1 : -1,
        col_position = col_positions_overflow(positions, homerow, rotations, col, cols)
    ) grid_pos_inner(
        col_position, homerow, rotations, angle,
        0, 0, 0,
        [0, 0, 0],
        col, homerow, row, dir, cols, rows
    );

function grid_pos_inner(col_position, homerow, rotations, angle, x, y, z, a, col, row, targetrow, dir, cols, rows) =
    row == targetrow
        ? let(
            b = [0, -angle, -col_position[0]],
            crot = key_rotations_overflow(rotations, col, homerow, cols, rows),
            pos = [x, y, z]
                * rotation_matrix([-crot[0], 0, 0])
                * rotation_matrix([0, -crot[1], 0])
                * rotation_matrix([0, 0, -crot[2]])
                * rotation_matrix([0, -angle, 0])
                * rotation_matrix([0, 0, -col_position[0]])
                + col_position[1] * rotation_matrix([0, b[1], 0])
        ) [pos, a - b + crot, rotation_matrix(a-b+crot)]
        : let(
            rotation = key_rotations_overflow(rotations, col, row + dir, cols, rows),
            rot = slice(rotation, 0, 3),
            offset =
                (row > 0 || (row == homerow && dir > 0)) && row < rows - 1
                ? key_vmargin + rotation[3]
                : col >= 0 && col < cols
                    ? key_size / 2 + border_width / 2
                    : key_size / 2,
            vec = [0, dir*offset, 0],
            pos2 = vec * rotation_matrix(a)
                 + vec * rotation_matrix(a + rot),
            x = x - pos2[0],
            y = y + pos2[1],
            z = z - pos2[2]
        ) grid_pos_inner(col_position, homerow, rotations, angle, x, y, z, a + rot, col, row + dir, targetrow, dir, cols, rows);

function key_offset(t, r, keys, col, row, offset=[0, 0, 0]) =
    let(
        key = keys[col+1][row+1]
    ) t + (key[0] + key[2] * offset) * r;

function top_bot_padding(pad, wdl=0, wdr=0, wtl=0, wtr=0) = 
    let(
        pad_change = [1, 0],
        p = [hpad_bot * pad[0], hpad_bot * pad[1], vpad_bot * pad[2], vpad_bot * pad[3],
             hpad_top * pad[0], hpad_top * pad[1], vpad_top * pad[2], vpad_top * pad[3]]
    ) [[p[0], p[2]], [p[1], p[2]], [p[1], p[3]], [p[0], p[3]], [p[4], p[6]], [p[5], p[6]], [p[5], p[7]], [p[4], p[7]]]
    + [wdl * pad_change, wdr * pad_change, wtr * pad_change, wtl * pad_change, [0, 0], [0, 0], [0, 0], [0, 0]];

function cube_points(t, r, keys, col, row, col_row_dir, zlo, zhi, pad, dx, dy) =
    let (
        x = key_size / 2 + dx,
        y = key_size / 2 + dy
    ) [
        for (i=[0:7])
        key_offset(t, r, keys, col + col_row_dir[i][0], row + col_row_dir[i][1],
            [col_row_dir[i][2] * (x + pad[i][0]), col_row_dir[i][3] * (y + pad[i][1]), i <= 3 ? zlo : zhi]),
    ];

function cube_points_vertical(t, r, keys, col, row, zhi=0, zlo=-grid_height, pad) =
    cube_points(t, r, keys, col, row, [
        [0, 0,  1, -1],
        [1, 0, -1, -1],
        [1, 0, -1,  1],
        [0, 0,  1,  1],
        [0, 0,  1, -1],
        [1, 0, -1, -1],
        [1, 0, -1,  1],
        [0, 0,  1,  1],
    ], zlo, zhi, pad, 0, 0);

function cube_points_horizontal(t, r, keys, col, row, zhi=0, zlo=-grid_height, pad) =
    cube_points(t, r, keys, col, row, [
        [0, 0, -1,  1],
        [0, 0,  1,  1],
        [0, 1,  1, -1],
        [0, 1, -1, -1],
        [0, 0, -1,  1],
        [0, 0,  1,  1],
        [0, 1,  1, -1],
        [0, 1, -1, -1],
    ], zlo, zhi, pad, 0, 0);

function cube_points_digaonal(t, r, keys, col, row, zhi=0, zlo=-grid_height, pad) =
    cube_points(t, r, keys, col, row, [
        [0, 0,  1,  1],
        [1, 0, -1,  1],
        [1, 1, -1, -1],
        [0, 1,  1, -1],
        [0, 0,  1,  1],
        [1, 0, -1,  1],
        [1, 1, -1, -1],
        [0, 1,  1, -1],
    ], zlo, zhi, pad, 0, 0);

function cube_points_body(t, r, keys, col, row, zhi=0, zlo=-grid_height, pad=[for (i=[0:7]) [0, 0]], dx=0, dy=0) =
    cube_points(t, r, keys, col, row, [
        [0, 0, -1, -1],
        [0, 0,  1, -1],
        [0, 0,  1,  1],
        [0, 0, -1,  1],
        [0, 0, -1, -1],
        [0, 0,  1, -1],
        [0, 0,  1,  1],
        [0, 0, -1,  1],
    ], zlo, zhi, pad, dx, dy);

 function cube_points_key(t, r, keys, col, row, zhi=8, zlo=0, pad=[for (i=[0:7]) [0, 0]]) =
    cube_points(t, r, keys, col, row, [
        [0, 0, -1*16/14, -1*16/14],
        [0, 0,  1*16/14, -1*16/14],
        [0, 0,  1*16/14,  1*16/14],
        [0, 0, -1*16/14,  1*16/14],
        [0, 0, -1*16/14, -1*16/14],
        [0, 0,  1*16/14, -1*16/14],
        [0, 0,  1*16/14,  1*16/14],
        [0, 0, -1*16/14,  1*16/14],
    ], zlo, zhi, pad, 0, 0);
 

module poly_cube(points) {
    polyhedron(points, [[0,1,2,3], [4,5,1,0], [7,6,5,4], [5,6,2,1], [6,7,3,2], [7,4,0,3]]);
}

module poly_cube_z0(top) {
    let (
        bot = [for (i=[0:3]) [top[i][0], top[i][1], 0]]
    ) poly_cube([each bot, each top]);
}

module poly_cube_zh(top, h) {
    let (
        bot = [for (i=[0:3]) [top[i][0], top[i][1], top[i][2]-h]]
    ) poly_cube([each bot, each top]);
}

module keyboard(positions, homerow, rotations, walls, angle, t=[0, 0, 0], rot=[0, 0, 0]) {
    cols = len(positions);
    rows = len(rotations);
    r = rotation_matrix(rot);
    r0 = rotation_matrix([0, 0, 0]);
    keys = let(
        keys = [for (col=[-1:cols]) [for (row=[-1:rows]) grid_pos(positions, homerow, rotations, angle, col, row)]],
        ks2 = key_size/2 + border_width,
        z = -border_height,
        low = [for (dim=[0:2])
            min([for (col=[1:cols]) for (row=[1:rows])
                for (offset=[[-ks2, -ks2, z], [-ks2, ks2, z], [ks2, -ks2, z], [ks2, ks2, z]])
                    (keys[col][row][0] + keys[col][row][2] * offset)[dim]
            ])
        ]
    ) [for (col=[0:cols+1]) [for (row=[0:rows+1])
        [keys[col][row][0] - [low[0], low[1], low[2] - base_extra_height], keys[col][row][1], keys[col][row][2]]
      ]];

    difference() {
        union() {
            for (col=[-1:cols-1]) {
                for (row=[-1:rows-1]) {
                    if (row >= 0 && (walls[2*row+1][2*col+1] == "x" || walls[2*row+1][2*col+3] == "x")) {
                        pad = top_bot_padding([
                            col == -1 || col == cols - 1 ? 0 : 1,
                            col == -1 || col == cols - 1 ? 0 : 1,
                            row == 0        ? 0 : 1,
                            row == rows - 1 ? 0 : 1
                        ]);
                        if (walls[2*row+1][2*col+2] == "|") {
                            points = cube_points_vertical(t, r, keys, col, row, 0, -border_height, pad);
                            lower = slice(points, 0, 4);
                            projected = project_down(lower);
                            poly_cube(points);
                            poly_cube([each projected, each lower]);
                        } else {
                            poly_cube(cube_points_vertical(t, r, keys, col, row, 0, -grid_height, pad));
                        }
                    }
                    skew = hpad_top - hpad_bot + border_hskew;
                    if (col >= 0 && (walls[2*row+1][2*col+1] == "x" || walls[2*row+3][2*col+1] == "x")) {
                        wdl = row == -1     && col >= 1
                            ? key_offset(t, r0, keys, col, row)[1] >= key_offset(t, r0, keys, col-1, row)[1]
                                ? -skew : skew : 0;
                        wdr = row == -1     && col < cols-1
                            ? key_offset(t, r0, keys, col, row)[1] >= key_offset(t, r0, keys, col+1, row)[1]
                                ? -skew : skew : 0;
                        wtl = row == rows-1 && col >= 1
                            ? key_offset(t, r0, keys, col, row)[1] <= key_offset(t, r0, keys, col-1, row)[1]
                                ? -skew : skew : 0;
                        wtr = row == rows-1 && col >= 0 && col < cols-1
                            ? key_offset(t, r0, keys, col, row)[1] <= key_offset(t, r0, keys, col+1, row)[1]
                                ? -skew : skew : 0;
                        pad = top_bot_padding([
                            col == 0        ? 0 : 1,
                            col == cols - 1 ? 0 : 1,
                            row == -1 || row == rows - 1 ? 0 : 1,
                            row == -1 || row == rows - 1 ? 0 : 1],
                            wdl=wdl, wdr=wdr, wtl=wtl, wtr=wtr);
                        if (walls[2*row+2][2*col+1] == "-") {
                            points = cube_points_horizontal(t, r, keys, col, row, 0, -border_height, pad);
                            lower = slice(points, 0, 4);
                            projected = project_down(lower);
                            poly_cube(points);
                            poly_cube([each projected, each lower]);
                        } else {
                            poly_cube(cube_points_horizontal(t, r, keys, col, row, 0, -grid_height, pad));
                        }
                    }
                    if (walls[2*row+1][2*col+1] == "x"
                     || walls[2*row+3][2*col+1] == "x"
                     || walls[2*row+1][2*col+3] == "x"
                     || walls[2*row+3][2*col+3] == "x") {
                        wdl = row == -1     && col >= 0 && col < cols-1
                            ? key_offset(t, r0, keys, col, row)[1] >= key_offset(t, r0, keys, col+1, row)[1]
                                ? -skew : skew
                            : 0;
                        wdr = row == -1     && col >= 0 && col < cols-1
                            ? key_offset(t, r0, keys, col, row)[1] <= key_offset(t, r0, keys, col+1, row)[1]
                                ? -skew : skew
                            : 0;
                        wtl = row == rows-1 && col >= 0 && col < cols-1
                            ? key_offset(t, r0, keys, col, row)[1] <= key_offset(t, r0, keys, col+1, row)[1]
                                ? -skew : skew
                            : 0;
                        wtr = row == rows-1 && col >= 0 && col < cols-1
                            ? key_offset(t, r0, keys, col, row)[1] >= key_offset(t, r0, keys, col+1, row)[1]
                                ? -skew : skew
                            : 0;
                        hpad = col == -1 || col == cols - 1 ? 0 : 1;
                        vpad = row == -1 || row == rows - 1 ? 0 : 1;
                        pad = top_bot_padding([hpad, hpad, vpad, vpad], wdl=wdl, wdr=wdr, wtl=wtl, wtr=wtr);
                        if (walls[2*row+2][2*col+2] != " " || walls[2*row+2][2*col+2] != " ") {
                            points = cube_points_digaonal(t, r, keys, col, row, 0, -border_height, pad);
                            lower = slice(points, 0, 4);
                            projected = project_down(lower);
                            poly_cube(points);
                            poly_cube([each projected, each lower]);
                        } else {
                            poly_cube(cube_points_digaonal(t, r, keys, col, row, 0, -grid_height, pad));
                        }
                    }
                }
            }

            for (col=[0:cols-1]) {
                for (row=[0:rows-1]) {
                    pad = top_bot_padding([col == 0 ? 0 : 1, col == cols-1 ? 0 : 1, row == 0 ? 0 : 1, row == rows-1 ? 0 : 1]);
                    if (walls[2*row+1][2*col+1] == "x") {
                        poly_cube(cube_points_body(t, r, keys, col, row, pad=pad));
                    }
                }
            }
            
            if (caps) {
                for (col=[0:cols-1]) {
                    for (row=[0:rows-1]) {
                        if (walls[2*row+1][2*col+1] == "x") {
                            poly_cube(cube_points_key(t, r, keys, col, row));
                        }
                    }
                }
            }
        }
        union() {
            for (col=[0:cols-1]) {
                for (row=[0:rows-1]) {
                    if (walls[2*row+1][2*col+1] == "x") {
                        poly_cube(cube_points_body(t, r, keys, col, row, 0.001, -grid_height-0.001, dx=0.001, dy=0.001));
                        poly_cube(cube_points_body(t, r, keys, col, row, -key_height, -key_height-insert_height, dx=insert_depth, dy=-insert_offset));
                        poly_cube(cube_points_body(t, r, keys, col, row, -key_height, -key_height-insert_height, dx=-insert_offset, dy=insert_depth));
                    }
                }
            }
        }
    }
}


difference() {
    brd_w = 18.5;
    brd_l = 24.25;
    brd_h = 1.3;
    brd_back = 1.65;
    
    usb_r = 1;
    usb_w = 9.3;
    usb_h = 3.4;
    usb_d = 0.6;
    usb_dd = 1.5;
    
    union() {
        keyboard(col_positions_thumb, 0, key_rotations_thumb, key_walls_thumb, 0, thumb_offset, thumb_rotation);
        keyboard(col_positions, 1, key_rotations, key_walls, angle);
        translate([4, 69.5, 1]) {
            translate([-2, -brd_l-4, -1]) {
                cube([3.249, brd_l+4, brd_w+2]);
            }
        }
    }
    union() {
        $fn=100;
        translate([-11, 18.4, 10]) {
            rotate([30, 90, 0]) {
                cylinder(h=7, r=4);
            }
        }
        
        translate([4,69.5, 1]) {
            $fn=100;
            for (i=[0, 1, 2]) {
                translate([-2.2,-brd_l-2, brd_w/2+i*3.6]) {
                    rotate([0, 90, 0]) {
                        cylinder(h=10, r=1.4);
                    }
                }
                translate([-2.2,-brd_l-2, brd_w/2-i*3.6]) {
                    rotate([0, 90, 0]) {
                        cylinder(h=10, r=1.4);
                    }
                }
            }
            
            translate([0, -brd_l, 0]) {
                cube([brd_h, brd_l, brd_w]);
            }
            translate([-brd_back, -brd_l+1, 1]) {
                cube([brd_back + 0.001, brd_l-2, brd_w-2]);
            }
            translate([usb_h/2+1, -2, brd_w/2]) {
                rotate([-90, -90, 0]) {
                    translate([-(usb_w-2*usb_r)/2, -usb_h/2, 0]) {
                        cube([usb_w-2*usb_r, usb_h, 15]);
                    }
                    translate([-usb_w/2, -(usb_h-2*usb_r)/2, 0]) {
                        cube([usb_w, usb_h-2*usb_r, 15]);
                    }
                    translate([-(usb_w-2*usb_r)/2, -(usb_h-2*usb_r)/2, 0]) {
                        cylinder(h=15, r=usb_r);
                    }
                    translate([(usb_w-2*usb_r)/2, -(usb_h-2*usb_r)/2, 0]) {
                        cylinder(h=15, r=usb_r);
                    }
                    translate([-(usb_w-2*usb_r)/2, (usb_h-2*usb_r)/2, 0]) {
                        cylinder(h=15, r=usb_r);
                    }
                    translate([(usb_w-2*usb_r)/2, (usb_h-2*usb_r)/2, 0]) {
                        cylinder(h=15, r=usb_r);
                    }
                }
            }
        }
    }
}
