assume cs: code, ss: stksg, ds: data

data segment
int9_offset dw 0
int9_segment dw 0
hello db 'hello world',0
left db 'left',0
right db 'right',0
data ends

stksg segment stack
db 2ffH dup (0)
stksg ends

code segment 
;函数: strlen(byte[] str)
;功能: 获取字符串长度
;参数: str 字符串首地址
;返回值: 字符串长度
strlen:		push bp
			mov bp, sp
			push bx
			push cx
			push si
			mov bx, [bp + 4]			;获取字符串首地址
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

;函数putc(byte char, byte property, byte y, byte x)
;功能: 将字符输出在指定位置
;参数: char: 字符， property: 输出属性, y: 纵坐标, x: 横坐标
putc:		push bp
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

			mov ax, 10
			mul bh
			add ax, 0b800H				;计算y坐标
			mov ds, ax

			shl bl, 1
			mov [bx], ch
			mov [bx + 1], cl

pc@ok:		pop cx
			pop bx
			pop ds
			pop bp
			ret 4
;函数putstr(byte[] str, byte x, byte y)
;功能: 在指定位置输出字符串
;参数: str: 字符串数组, x: 横坐标, y: 纵坐标 
putstr:		push bp
			mov bp, sp
			push bx
			push cx
			push si
			push es
			mov si, [bp + 4]		;字符串地址
			mov bx, [bp + 6]		;bh:Y坐标, bl: X坐标
			push [bp + 4]
			call strlen				;获取字符串长度
			mov cx, ax
			mov ax, 10				;计算Y坐标
			mul bh
			add ax, 0b800H
			mov es, ax

			shl	bl			;计算X坐标
			mov bh, 0
ps@p:		mov al, [si]			;读取字符 输出到显示缓冲区
			mov es:[bx], al
			mov byte ptr es:[bx + 1], 00000111B
			inc si
			add bx, 2
			loop ps@p

			pop es
			pop si
			pop cx
			pop bx
			pop bp
			ret 4

;中断9 键盘控制
int9:		push bp		
			mov bp, sp
			push ax
			push es
			in al, 60H					;从端口60读取键盘输入
			pushf					;标志寄存器入栈
			call dword ptr [int9_offset]	;调用原始int9中断
			cmp al, 4bH
			je on@left
			cmp al, 4dH
			je on@right
			cmp al, 1
			je on@esc
			jmp int9@ret
on@left:	mov ax, 0
			push ax
			mov ax, offset left
			push ax
			call putstr
			jmp int9@ret

on@right:	mov ax, 0
			push ax
			mov ax, offset right
			push ax
			call putstr
			jmp int9@ret

;恢复int9向量表并退出程序
on@esc:		mov ax, 0
			mov es, ax
			push [int9_offset]
			pop es:[9 * 4]
			push [int9_segment]
			pop es:[9 * 4 + 2] 

			mov word ptr [bp+2], offset exit
			mov [bp + 4], cs

int9@ret:	pop es
			pop ax
			pop bp
			iret

main:		mov ax, 0003H
			int 10H

;设置栈段和数据段
			mov ax, stksg
			mov ss, ax
			mov sp, 02ffH
			mov ax, data
			mov ds, ax
;安装int9中断
			mov ax, 0
			mov es, ax
;保存原始int9中断段地址和偏移量
			push es:[9 * 4]			
			pop [int9_offset]
			push es:[9 * 4 + 2]
			pop [int9_segment]
;替换中断向量表
			cli						;禁止中断 
			mov word ptr es:[9 * 4], offset int9;替换中断向量表
			mov es:[9 * 4 + 2], cs
			sti						;允许中断

s:			mov cx, 2
			loop s

exit:		mov ax, 4c00H
			int 21H
code ends
end main


