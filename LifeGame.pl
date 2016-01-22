cell_change_state(dead_cell, 3, live_cell).

cell_change_state(live_cell, Neighbours, live_cell) :-
  member(Neighbours, [2, 3]).

cell_change_state(_, _, dead_cell).

down_cell(cell(X, Y), cell(X, NY)) :- NY is Y - 1.
up_cell(cell(X, Y), cell(X, NY)) :- NY is Y + 1.
left_cell(cell(X, Y), cell(NX, Y)) :- NX is X - 1.
right_cell(cell(X, Y), cell(NX, Y)) :- NX is X + 1.

right_up_cell(cell(X, Y), cell(NX, NY)) :- NX is X + 1, NY is Y +1.

left_up_cell(cell(X, Y), cell(NX, NY)) :- NX is X -1, NY is Y + 1.

right_down_cell(cell(X, Y), cell(NX, NY)) :- NX is X + 1, NY is Y -1.

left_down_cell(cell(X, Y), cell(NX, NY)) :- NX is X - 1, NY is Y -1.

neighbours(Cell, Neighbours) :-
  right_down_cell(Cell, RDC),
  down_cell(Cell, DC),
  left_down_cell(Cell, LDC),
  right_cell(Cell, RC),
  right_up_cell(Cell, RUC),
  up_cell(Cell, UC),
  left_up_cell(Cell, LUC),
  left_cell(Cell, LC),
  list_to_set([RDC, DC, LDC, RC, RUC, UC, LUC, LC], Neighbours).

create_empty_world(world([], [])).

world_add_cell(world(LiveCells, DeadCells), Cell, world(UnionLiveCells, NewDeadCells)) :-
  union([Cell], LiveCells, UnionLiveCells),
  neighbours(Cell, Neighbours),
  union(DeadCells, Neighbours, DeadCellsUnion),
  subtract(DeadCellsUnion, UnionLiveCells, NewDeadCells).

world_add_cells(World, [], World).

world_add_cells(World, [H|T], NewWorld) :-
  world_add_cell(World, H, IntermediateWorld),
  world_add_cells(IntermediateWorld, T, NewWorld).

live_neighbours_from_live_set(LiveCells, Cell, LiveNeighbours) :-
  neighbours(Cell, Neighbours),
  intersection(LiveCells, Neighbours, LiveNeighbours).

live_neighbours(world(LiveCells, _), Cell, LiveNeighbours) :-
  live_neighbours_from_live_set(LiveCells, Cell, LiveNeighbours).

try_to_insert_cell_new_world(World, _, dead_cell, World).

try_to_insert_cell_new_world(World, Cell, live_cell, NewWorld) :-
  world_add_cell(World, Cell, NewWorld).

evolve_util(InitialWorld, world(LiveCells, DeadCells), PartialNextGenWorld, NextGenWorld) :-
  evolve_util_for_cells_set(live_cell, InitialWorld, LiveCells, PartialNextGenWorld, NextGenLiveEvolved),
  evolve_util_for_cells_set(dead_cell, InitialWorld, DeadCells, NextGenLiveEvolved, NextGenWorld).

evolve_util_for_cells_set(_, _, [], NextGenWorld, NextGenWorld).

evolve_util_for_cells_set(ExpectedCellState, InitialWorld, [Cell|LiveTail], PartialNextGenWorld, NextGenWorld) :-
  live_neighbours(InitialWorld, Cell, LiveNeighbours),
  length(LiveNeighbours, NLiveNeighbours),
  cell_change_state(ExpectedCellState, NLiveNeighbours, NewCellState),
  try_to_insert_cell_new_world(PartialNextGenWorld, Cell, NewCellState, LessPartialNextGenWorld),
  subtract([Cell|LiveTail], [Cell], LiveRemains), % keeps set structure
  evolve_util_for_cells_set(ExpectedCellState, InitialWorld, LiveRemains, LessPartialNextGenWorld, NextGenWorld).

evolve(World, NextGenWorld) :-
  create_empty_world(EmptyWorld),
  evolve_util(World, World, EmptyWorld, NextGenWorld).

% 48 is ascii('0')
cell_to_string(world(LiveCells, _), X, Y, [48]) :-
  intersection([cell(X, Y)], LiveCells, [cell(X, Y)]).

% 32 is ascii(' ')
cell_to_string(_, _, _, [32]).

% 10 is ascii('\n')
world_line_to_string(_, _, _, 0, Acc, WithBreakLine) :-
  append(Acc, [10], WithBreakLine).

world_line_to_string(World, X, Y, Width, Acc, LineString) :-
  NextX is X + 1,
  RemainWidth is Width - 1,
  cell_to_string(World, X, Y, CellString),
  append(Acc, CellString, NewAcc),
  world_line_to_string(World, NextX, Y, RemainWidth, NewAcc, LineString).

world_to_string_codes_util(_, world_window(_, _, 0, _), Acc, Acc).

world_to_string_codes_util(World, world_window(X, Y, Height, Width), Acc, WorldArray) :-
  world_line_to_string(World, X, Y, Width, Acc, PartialArray),
  NextLine is Y + 1,
  RemainHeight is Height - 1,
  world_to_string_codes_util(World, world_window(X, NextLine, RemainHeight, Width), PartialArray, WorldArray).

world_to_string_codes(World, Window, WorldArray) :-
  world_to_string_codes_util(World, Window, [], WorldArray).

world_to_string(World, Window, WorldString) :-
  world_to_string_codes(World, Window, WorldArray),
  string_to_list(WorldString, WorldArray).

game_of_life_main_loop(World, Window) :-
  world_to_string(World, Window, WorldString),
  evolve(World, EvolvedWorld),
  sleep(0.5), % sleeps 1s
  write('\e[H\e[2J'), % clear screen
  write(WorldString),
  game_of_life_main_loop(EvolvedWorld, Window).

% список живых клеток и область окна  
game_of_life(Cells, Window) :-
  create_empty_world(EmptyWorld),
  world_add_cells(EmptyWorld, Cells, NewWorld),
  game_of_life_main_loop(NewWorld, Window).

% тестовая цель - планер
main(_) :- game_of_life([cell(2,1), cell(3,2), cell(3,3), cell(2,3), cell(1,3)], world_window(0,0,20,20)).