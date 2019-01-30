assume cs: code, ss: stksg, ds: data

data segment
int9_offset dw 0
int9_segment dw 0
keyboard_handler dw 0
left db 'left',0
start_tips db 'press any key to start...', 0
signature_filename db 'SIGN.TXT', 0
signature db 151H dup(0)
data ends

stksg segment stack
db 300H dup (0)
stksg ends

code segment 
;函数:		initial()
;功能:		进行初始化
initial proc
;清屏
			push cx
			mov ax, 0003H
			int 10H
;禁止光标闪烁
			mov ch, 00100000B
			mov cl, 0
			mov ah, 1
			int 10H
			pop cx
			ret
initial endp
;函数:		strlen(byte[] str)
;功能:		获取字符串长度
;参数:		str 字符串首地址
;返回值:	字符串长度
strlen proc
			push bp
			mov bp, sp
			push bx
			push cx
			push si
			mov bx, [bp + 4]			;获取字符串首地址
			xor si, si
			xor cx, cx
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
strlen endp

;函数putc(byte char, byte property, byte y, byte x)
;功能:		将字符输出在指定位置
;参数:		char: 字符， property: 输出属性, y: 纵坐标, x: 横坐标
putc proc	
			push bp
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
			xor bh, bh
			mov [bx], ch
			mov [bx + 1], cl

pc@ok:		pop cx
			pop bx
			pop ds
			pop bp
			ret 4
putc endp
;函数putstr(byte[] str, byte y, byte x)
;功能:		在指定位置输出字符串
;参数:		str: 字符串数组, x: 横坐标, y: 纵坐标 
putstr proc	
			push bp
			mov bp, sp
			push bx
			push cx
			push si
			push es
			mov si, [bp + 4]		;字符串地址
			push [bp + 4]
			call strlen				;获取字符串长度
			mov cx, ax

			mov ax, 10				;计算Y坐标
			mul byte ptr [bp + 7]	
			add ax, 0b800H
			mov es, ax

			shl	byte ptr [bp + 6], 1		;计算X坐标
			xor bx, bx
			mov bl, [bp + 6]
ps@p:		mov al, [si]			;读取字符 输出到显示缓冲区
			cmp al, 0aH
			jne ps@d
			mov ax, es
			add ax, 10
			mov es, ax
			mov bl, [bp + 6]
			jmp ps@lp
ps@d:		mov es:[bx], al
			mov byte ptr es:[bx + 1], 00000111B
			add bx, 2
ps@lp:		inc si
			loop ps@p

			pop es
			pop si
			pop cx
			pop bx
			pop bp
			ret 4
putstr endp


;函数draw_rec(byte y, byte x, byte width, byte height)
;功能: 在指定位置绘制方框
;参数: x: 横坐标, y: 纵坐标, width: 宽度, heigh: 高度
draw_rec proc
			push bp
			mov bp, sp
			push cx
			push es
			push ds
			push si
			push bx

			mov ax, 10			;计算纵坐标
			mul byte ptr [bp + 5]
			add ax, 0b800H
			mov ds, ax

			mov ax, 10
			dec byte ptr [bp + 6]
			mul byte ptr [bp + 6]
			mov bx, ds
			add ax, bx
			mov es, ax

;绘制水平边
			xor bx, bx
			mov bl, [bp + 4]	;横坐标
			shl bl, 1
			xor cx, cx
			mov cl, [bp + 7]	;宽度
			mov byte ptr ds:[bx], '+'
			mov byte ptr ds:[bx + 1], 00000111B
			mov byte ptr es:[bx], '+'
			mov byte ptr es:[bx + 1], 00000111B
			add bx, 2
			sub cx, 2
dr@horizon:	mov byte ptr ds:[bx], '-'
			mov byte ptr ds:[bx + 1], 00000111B		;黑底白字
			mov byte ptr es:[bx], '-'
			mov byte ptr es:[bx + 1], 00000111B
			add bx, 2
			loop dr@horizon
			mov byte ptr ds:[bx], '+'
			mov byte ptr ds:[bx + 1], 00000111B
			mov byte ptr es:[bx], '+'
			mov byte ptr es:[bx + 1], 00000111B

;绘制竖直边
			mov bx, [bp + 4]
			shl bl, 1			;计算横坐标
			xor bh, bh

			mov cl, [bp + 7]
			xor ch, ch
			dec cl
			shl cl, 1
			mov si, cx
			add si, bx

			mov ax, ds
			mov cx, es
dr@vertical:add ax, 10
			cmp ax, cx
			je dr@ret
			mov ds, ax
			mov byte ptr ds:[bx], '|'
			mov byte ptr ds:[bx + 1], 00000111B
			mov byte ptr ds:[si], '|'
			mov byte ptr ds:[si + 1], 00000111B
			jmp dr@vertical

dr@ret:		pop bx
			pop si
			pop ds	
			pop	es	
			pop cx
			pop bp
			ret 4
draw_rec endp
;函数read_file(byte[] filename, byte[] buffer, word length)
;功能:		从文件读取内容
;参数:		filename	文件名
;			buffer		读入地址
;			length		长度
;返回值:	 0		成功
;			其他	失败	
read_file proc
			push bp
			mov bp, sp
			push bx
			push cx
			push dx
;打开文件
			mov dx, [bp + 4]
			mov ah, 3dH
			mov al, 2
			int 21H
			jc rf@err
;读取文件内容
			mov bx, ax
			xor ax, ax
			mov ah, 3fH
			mov dx, [bp + 6]
			mov cx, [bp + 8]
			int 21H
			jc rf@err
;关闭文件
			xor ax, ax
			mov ah, 3eH
			int 21H
			jc rf@err
			mov ax, 0

rf@err:		pop dx
			pop cx
			pop bx
			pop bp
			ret 6
read_file endp

;函数:	write_file(byte[] filename, byte[] buffer, word length, word append)
;功能:	写入数据到文件
;参数:	filename	文件名
;		buffer		数据
;		length		数据长度
;		append		1:追加	0:覆盖
;返回值:	0		成功
;			其他	失败
write_file proc
			push bp
			mov bp, sp
			sub sp, 2	;申请栈空间 存放文件句柄 [bp - 2]
			push dx
			push cx
			push bx
			mov ax, [bp + 10]
			test ax, ax
			je wf@create
wf@open:	mov ax, 3d01H
			mov dx,	[bp + 4]
			int 21H
;打开文件失败尝试创建文件
			mov [bp - 2], ax
			jc wf@create
;移动文件指针至末尾
			mov bx, [bp - 2]
			mov cx, 0
			mov dx, 0
			mov al, 2
			mov ah, 42H
			int 21H
			jc wf@close
			jmp wf@write
wf@create:	mov cx, 80H		;文件属性 share
			mov dx, [bp + 4]
			mov ah, 3cH
			int 21H
			mov [bp - 2], ax
			jc wf@err
wf@write:	mov dx, [bp + 6]
			mov bx, [bp - 2]
			mov cx, [bp + 8]
			mov ah, 40H
			int 21H
			jc wf@err
			mov ax, 0
wf@close:	mov ah, 3eH
			mov bx, [bp -2]
			int 21H
			jc wf@err

wf@err:		pop bx
			pop cx
			pop dx
			pop bp
			add sp, 2
			ret 8
write_file endp

;函数:	regist_keyboardhandler(function handler(byte key))
;功能:	注册键盘处理函数
;参数:	handler 键盘处理函数 接受一个byte参数
regist_keyboardhandler proc
			jmp rgt@begin		;跳转到函数开始
;中断9 键盘控制
int9:		push bp		
			mov bp, sp
			push ax
			push es
			in al, 60H					;从端口60读取键盘输入
			pushf					;标志寄存器入栈
			call dword ptr [int9_offset]	;调用原始int9中断
			cmp al, 1
			je on@esc
			xor ah, ah
			push ax
			call word ptr [keyboard_handler]
			jmp int9@ret
;恢复int9向量表并退出程序
on@esc:		xor ax, ax
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

rgt@begin:	push bp
			mov bp, sp
			push es

			xor ax, ax
			mov es, ax
;设置键盘处理器
			mov ax, [bp + 4]
			mov word ptr [keyboard_handler], ax
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

			pop es
			pop bp
			ret 2
regist_keyboardhandler endp

test_keyboardhandler proc
			push bp
			mov bp, sp
			mov ax, [bp + 4]
			cmp al, 4bH
			je on@left
			jmp handler@ret
on@left:	xor ax, ax
			push ax
			mov ax, offset left
			push ax
			call putstr

handler@ret:pop bp
			ret 2
test_keyboardhandler endp


;设置栈段和数据段
main:		mov ax, stksg
			mov ss, ax
			mov sp, 0300H
			mov ax, data
			mov ds, ax
;初始化
			call initial

;绘制方框
			mov ah, 80
			mov al, 25
			push ax
			xor ax, ax
			mov ah, 0
			mov al, 0
			push ax
			call draw_rec

;读取asm game标志文件
			mov ax, 150H
			push ax
			mov ax, offset signature
			push ax
			mov ax, offset signature_filename
			push ax
			call read_file
			mov ah, 3
			mov al, 12
			push ax
			mov ax, offset signature
			push ax
			call putstr
			mov ah, 12
			mov al, 25
			push ax
			mov ax, offset start_tips
			push ax
			call putstr

;注册键盘处理程序
			mov ax, offset test_keyboardhandler 
			push ax
			call regist_keyboardhandler
s:			mov cx, 2
			loop s

exit:		mov ax, 4c00H
			int 21H
code ends
end main
