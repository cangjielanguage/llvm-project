; RUN: llc -mtriple=armv7a-linux-android23 -mcpu=cortex-a9 -relocation-model=pic -frame-pointer=non-leaf -cangjie-pipeline -verify-machineinstrs -stop-after=virtregrewriter < %s | FileCheck %s --check-prefix=MIR
; RUN: llc -mtriple=armv7a-linux-android23 -mcpu=cortex-a9 -relocation-model=pic -frame-pointer=non-leaf -cangjie-pipeline -verify-machineinstrs < %s | FileCheck %s --check-prefix=ASM
;
; A reduced stack-address case from RenderOptions.deserialize. No inline asm
; or fixed-register constraints. LocalStackSlotAllocation materializes a base
; for the two halfword stores before the stack check. R12 must not carry that
; base across the call because an ARM PLT overwrites it.
; Use the generic GC strategy to isolate call/regmask lowering from CJ frame
; generation and stack-pointer metadata (the call convention remains CangjieGC).

; MIR-LABEL: name: repro
; MIR: renamable $[[BASE:r([0-9]|10|11)]] = ADDri %stack.1.tag, 0,
; MIR: STATEPOINT 5, {{.*}}@CJ_MCC_StackCheck, {{.*}}csr_cangjiegc_noip,
; MIR: STRH {{.*}}$[[BASE]], $noreg, 0,
; MIR: STRH {{.*}}$[[BASE]], $noreg, 0,

; ASM-LABEL: repro:
; ASM: sub sp, sp, #{{[0-9]+}}
; ASM-NEXT: add [[BASE:r([0-9]|10|11)]], sp, #{{[0-9]+}}
; ASM: bl CJ_MCC_StackGrowStub
; ASM: strh {{r[0-9]+}}, {{\[}}[[BASE]]{{\]}}
; ASM: strh {{r[0-9]+}}, {{\[}}[[BASE]]{{\]}}

target triple = "armv7a-linux-android23"

declare void @CJ_MCC_StackCheck() #0
declare token @llvm.cj.gc.statepoint(...)
declare void @consume(i8*, i8*, i8*, i32, i32, i32)

define void @repro(i32 %a0, i32 %a1, i32 %a2) gc "statepoint-example" {
entry:
  %left = alloca [160 x i8], align 8
  %tag = alloca i16, align 8
  %right = alloca [160 x i8], align 8
  %p = bitcast i16* %tag to i8*
  %l = bitcast [160 x i8]* %left to i8*
  %r = bitcast [160 x i8]* %right to i8*
  %token = call cangjiegccc token (...) @llvm.cj.gc.statepoint(i64 5, i32 0, void ()* @CJ_MCC_StackCheck, i32 0, i32 0)
  store volatile i16 0, i16* %tag, align 8
  store volatile i16 1, i16* %tag, align 8
  %other = call token (...) @llvm.cj.gc.statepoint(i64 0, i32 0, void (i8*, i8*, i8*, i32, i32, i32)* @consume, i32 6, i32 0, i8* %l, i8* %p, i8* %r, i32 %a0, i32 %a1, i32 %a2)
  ret void
}

attributes #0 = { "cj-stack-check" }
