.rodata
_msg_lives:  .asciiz "  Lives: "
_msg_win:    .asciiz "You win!"
_msg_lose:   .asciiz "You lost!"

.code
.export minesweeper_init
minesweeper_init:
    rts
