//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Optimum Application-Specific Integrated System Laboratory
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Spring
//   Lab09  : Online Shopping Platform Simulation
//   Author : Zhi-Ting Dong (yjdzt918.ee11@nycu.edu.tw)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : Usertype_OS.sv
//   Module Name : usertype
//   Release version : V1.0 (Release Date: 2023-04)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`ifndef USERTYPE
`define USERTYPE

package usertype;

typedef enum logic [3:0] { 
	No_action	= 4'd0,
	Buy			= 4'd1,
	Check		= 4'd2,
	Deposit		= 4'd4, 
	Return		= 4'd8 
}	Action ;

typedef enum logic [3:0] { 
	No_Err			= 4'b0000, //	No error
	INV_Not_Enough	= 4'b0010, //	Seller's inventory is not enough
	Out_of_money	= 4'b0011, //	Out of money
	INV_Full		= 4'b0100, //	User's inventory is full 
	Wallet_is_Full	= 4'b1000, //	Wallet is full
	Wrong_ID		= 4'b1001, //	Wrong seller ID 
	Wrong_Num		= 4'b1100, //	Wrong number
	Wrong_Item		= 4'b1010, //	Wrong item
	Wrong_act		= 4'b1111  //	Wrong operation
}	Error_Msg ;

typedef enum logic [1:0]	{ 
	Platinum	= 2'b00,
	Gold		= 2'b01,
	Silver		= 2'b10,
	Copper		= 2'b11
}	User_Level ;				

typedef enum logic [1:0] {
	No_item	= 2'd0,
	Large	= 2'd1,
	Medium	= 2'd2,
	Small	= 2'd3
}	Item_id ;


typedef logic [7:0] User_id;
typedef logic [5:0] Item_num;
typedef logic [15:0] Money;
typedef logic [11:0] EXP;
typedef logic [15:0] Item_num_ext;

typedef struct packed {
	Item_id		item_ID;
	Item_num	item_num;
	User_id		seller_ID;
}	Shopping_His; // Shopping History

typedef struct packed {
	Item_num		large_num;
	Item_num		medium_num;
	Item_num		small_num;
	User_Level		level;
	EXP				exp;
}	Shop_Info; //Shop info

typedef struct packed {
	Money 			money; 
	Shopping_His 	shop_history;
}	User_Info; //User info

typedef union packed { 	
	Money			d_money;
	User_id	[1:0]	d_id;
	Action	[3:0]	d_act;
	Item_id	[7:0]	d_item;
	Item_num_ext	d_item_num;
} DATA;

//################################################## Don't revise the code above
typedef enum logic [3:0] {
	OS_IDLE = 4'd0,
	S_BUYER,
	S_CAL,
	S_CHECK_DEPOSIT,
	S_BUY_RETURN,
	S_SELLER,
	S_VALIDITY,
	S_WAIT_READ_S,
	S_WAIT_READ_B,
	S_WAIT_WRITE_B,
	S_WAIT_WRITE_S,
	S_ACT,
	S_OUT=4'd12
} STATE_OS;
typedef struct packed {
	User_Info user;
	Shop_Info shop;
}     PERSON;

typedef enum logic [2:0] {
	S_IDLE = 3'd0,
	S_READ_READY,
	S_READ,
	S_READ_OUT,
	S_WRITE_READY,
	S_WRITE,
	S_RESPONSE,
	S_WRITE_OUT= 3'd7
} STATE_BR;


//################################################## Don't revise the code below
endpackage
import usertype::*; //import usertype into $unit

`endif

