assume cs: code, ss: stksg, ds: data

data segment
hello db 'hello world',0
data ends

stksg segment stack
db 20 dup (0)
stksg ends

code segment 
;函数: strlen(byte[] str)
;功能: 获取字符串长度
;参数: str 字符串首地址
;返回值: 字符串长度
strlen:		push bp
			push bx
			push cx
			push si
			mov bp, sp
			mov bx, [bp + 10]			;获取字符串首地址
			mov si, 0
			mov cx, 0
sl@char:	mov cl, [bx + si]			;取出字符
			jcxz sl@ok
			inc si
			jmp sl@char

sl@ok:		mov ax, si
			pop si
			pop cx
			pop bx
			pop bp
			ret 2

;函数putch(byte char, byte property, byte y, byte x)
;功能: 将字符输出在指定位置
;参数: char: 字符， property: 输出属性, y: 纵坐标, x: 横坐标
putch:		push bp
			mov bp, sp
			push ds 
			push bx
			push cx
			mov cx, [bp + 4]		;ch char字符, cl property属性
			mov bx, [bp + 6]		;bl x坐标, bh y坐标
			cmp bl, 79				;检查坐标参数
			ja pc@ok
			cmp bh, 24
			ja pc@ok

			mov ax, 20
			mul bh
			add ax, 0b800H				;计算y坐标
			mov ds, ax
			mov ax, 2
			mul bl
			mov bx, ax
			mov [bx], ch
			mov [bx + 1], cl

pc@ok:		pop cx
			pop bx
			pop ds
			pop bp
			ret 4

main:		mov ax, 0003H
			int 10H
			mov ax, stksg
			mov ss, ax
			mov sp, 20
			mov ax, data
			mov ds, ax
			mov ah, 12
			mov al, 60
			push ax
			mov ah, 'A'
			mov al, 01000010B
			push ax
			call putch
			mov ax, 4c00H
			int 21H
code ends
end main


