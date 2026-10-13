; ModuleID = '/workspace/user-programs/computed_goto.c'
source_filename = "/workspace/user-programs/computed_goto.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@run.ops = internal constant [3 x ptr] [ptr blockaddress(@run, %increment), ptr blockaddress(@run, %double_it), ptr blockaddress(@run, %stop)], align 16, !dbg !0
@__const.main.program = private unnamed_addr constant [5 x i8] c"\00\01\00\01\02", align 1

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @run(ptr noundef %code, i32 noundef %n) #0 !dbg !2 {
entry:
  %retval = alloca i32, align 4
  %code.addr = alloca ptr, align 8
  %n.addr = alloca i32, align 4
  %value = alloca i32, align 4
  %pc = alloca i32, align 4
  store ptr %code, ptr %code.addr, align 8
    #dbg_declare(ptr %code.addr, !27, !DIExpression(), !28)
  store i32 %n, ptr %n.addr, align 4
    #dbg_declare(ptr %n.addr, !29, !DIExpression(), !30)
    #dbg_declare(ptr %value, !31, !DIExpression(), !32)
  store i32 0, ptr %value, align 4, !dbg !32
    #dbg_declare(ptr %pc, !33, !DIExpression(), !34)
  store i32 0, ptr %pc, align 4, !dbg !34
  %0 = load ptr, ptr %code.addr, align 8, !dbg !35
  %1 = load i32, ptr %pc, align 4, !dbg !36
  %idxprom = sext i32 %1 to i64, !dbg !35
  %arrayidx = getelementptr inbounds i8, ptr %0, i64 %idxprom, !dbg !35
  %2 = load i8, ptr %arrayidx, align 1, !dbg !35
  %idxprom1 = zext i8 %2 to i64, !dbg !37
  %arrayidx2 = getelementptr inbounds nuw [3 x ptr], ptr @run.ops, i64 0, i64 %idxprom1, !dbg !37
  %3 = load ptr, ptr %arrayidx2, align 8, !dbg !37
  br label %indirectgoto, !dbg !38

increment:                                        ; preds = %indirectgoto
    #dbg_label(!39, !40)
  %4 = load i32, ptr %value, align 4, !dbg !41
  %add = add nsw i32 %4, 1, !dbg !41
  store i32 %add, ptr %value, align 4, !dbg !41
  %5 = load i32, ptr %pc, align 4, !dbg !42
  %inc = add nsw i32 %5, 1, !dbg !42
  store i32 %inc, ptr %pc, align 4, !dbg !42
  %6 = load i32, ptr %n.addr, align 4, !dbg !44
  %cmp = icmp sge i32 %inc, %6, !dbg !45
  br i1 %cmp, label %if.then, label %if.end, !dbg !45

if.then:                                          ; preds = %increment
  %7 = load i32, ptr %value, align 4, !dbg !46
  store i32 %7, ptr %retval, align 4, !dbg !47
  br label %return, !dbg !47

if.end:                                           ; preds = %increment
  %8 = load ptr, ptr %code.addr, align 8, !dbg !48
  %9 = load i32, ptr %pc, align 4, !dbg !49
  %idxprom3 = sext i32 %9 to i64, !dbg !48
  %arrayidx4 = getelementptr inbounds i8, ptr %8, i64 %idxprom3, !dbg !48
  %10 = load i8, ptr %arrayidx4, align 1, !dbg !48
  %idxprom5 = zext i8 %10 to i64, !dbg !50
  %arrayidx6 = getelementptr inbounds nuw [3 x ptr], ptr @run.ops, i64 0, i64 %idxprom5, !dbg !50
  %11 = load ptr, ptr %arrayidx6, align 8, !dbg !50
  br label %indirectgoto, !dbg !51

double_it:                                        ; preds = %indirectgoto
    #dbg_label(!52, !53)
  %12 = load i32, ptr %value, align 4, !dbg !54
  %mul = mul nsw i32 %12, 2, !dbg !54
  store i32 %mul, ptr %value, align 4, !dbg !54
  %13 = load i32, ptr %pc, align 4, !dbg !55
  %inc7 = add nsw i32 %13, 1, !dbg !55
  store i32 %inc7, ptr %pc, align 4, !dbg !55
  %14 = load i32, ptr %n.addr, align 4, !dbg !57
  %cmp8 = icmp sge i32 %inc7, %14, !dbg !58
  br i1 %cmp8, label %if.then9, label %if.end10, !dbg !58

if.then9:                                         ; preds = %double_it
  %15 = load i32, ptr %value, align 4, !dbg !59
  store i32 %15, ptr %retval, align 4, !dbg !60
  br label %return, !dbg !60

if.end10:                                         ; preds = %double_it
  %16 = load ptr, ptr %code.addr, align 8, !dbg !61
  %17 = load i32, ptr %pc, align 4, !dbg !62
  %idxprom11 = sext i32 %17 to i64, !dbg !61
  %arrayidx12 = getelementptr inbounds i8, ptr %16, i64 %idxprom11, !dbg !61
  %18 = load i8, ptr %arrayidx12, align 1, !dbg !61
  %idxprom13 = zext i8 %18 to i64, !dbg !63
  %arrayidx14 = getelementptr inbounds nuw [3 x ptr], ptr @run.ops, i64 0, i64 %idxprom13, !dbg !63
  %19 = load ptr, ptr %arrayidx14, align 8, !dbg !63
  br label %indirectgoto, !dbg !64

stop:                                             ; preds = %indirectgoto
    #dbg_label(!65, !66)
  %20 = load i32, ptr %value, align 4, !dbg !67
  store i32 %20, ptr %retval, align 4, !dbg !68
  br label %return, !dbg !68

return:                                           ; preds = %stop, %if.then9, %if.then
  %21 = load i32, ptr %retval, align 4, !dbg !69
  ret i32 %21, !dbg !69

indirectgoto:                                     ; preds = %if.end10, %if.end, %entry
  %indirect.goto.dest = phi ptr [ %3, %entry ], [ %11, %if.end ], [ %19, %if.end10 ]
  indirectbr ptr %indirect.goto.dest, [label %increment, label %double_it, label %stop]
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @main() #0 !dbg !70 {
entry:
  %retval = alloca i32, align 4
  %program = alloca [5 x i8], align 1
  store i32 0, ptr %retval, align 4
    #dbg_declare(ptr %program, !73, !DIExpression(), !77)
  call void @llvm.memcpy.p0.p0.i64(ptr align 1 %program, ptr align 1 @__const.main.program, i64 5, i1 false), !dbg !77
  %arraydecay = getelementptr inbounds [5 x i8], ptr %program, i64 0, i64 0, !dbg !78
  %call = call i32 @run(ptr noundef %arraydecay, i32 noundef 5), !dbg !79
  %cmp = icmp eq i32 %call, 6, !dbg !80
  %0 = zext i1 %cmp to i64, !dbg !79
  %cond = select i1 %cmp, i32 0, i32 1, !dbg !79
  ret i32 %cond, !dbg !81
}

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1

attributes #0 = { noinline nounwind uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }

!llvm.dbg.cu = !{!10}
!llvm.module.flags = !{!19, !20, !21, !22, !23, !24, !25}
!llvm.ident = !{!26}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(name: "ops", scope: !2, file: !3, line: 2, type: !14, isLocal: true, isDefinition: true)
!2 = distinct !DISubprogram(name: "run", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !10, retainedNodes: !13)
!3 = !DIFile(filename: "user-programs/computed_goto.c", directory: "/workspace", checksumkind: CSK_MD5, checksum: "e6deaafbfcb1514f91bb07878ad5625d")
!4 = !DISubroutineType(types: !5)
!5 = !{!6, !7, !6}
!6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !8, size: 64)
!8 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !9)
!9 = !DIBasicType(name: "unsigned char", size: 8, encoding: DW_ATE_unsigned_char)
!10 = distinct !DICompileUnit(language: DW_LANG_C11, file: !11, producer: "clang version 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, globals: !12, splitDebugInlining: false, nameTableKind: None)
!11 = !DIFile(filename: "/workspace/user-programs/computed_goto.c", directory: "/workspace", checksumkind: CSK_MD5, checksum: "e6deaafbfcb1514f91bb07878ad5625d")
!12 = !{!0}
!13 = !{}
!14 = !DICompositeType(tag: DW_TAG_array_type, baseType: !15, size: 192, elements: !17)
!15 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !16)
!16 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
!17 = !{!18}
!18 = !DISubrange(count: 3)
!19 = !{i32 7, !"Dwarf Version", i32 5}
!20 = !{i32 2, !"Debug Info Version", i32 3}
!21 = !{i32 1, !"wchar_size", i32 4}
!22 = !{i32 8, !"PIC Level", i32 2}
!23 = !{i32 7, !"PIE Level", i32 2}
!24 = !{i32 7, !"uwtable", i32 2}
!25 = !{i32 7, !"frame-pointer", i32 2}
!26 = !{!"clang version 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)"}
!27 = !DILocalVariable(name: "code", arg: 1, scope: !2, file: !3, line: 1, type: !7)
!28 = !DILocation(line: 1, column: 30, scope: !2)
!29 = !DILocalVariable(name: "n", arg: 2, scope: !2, file: !3, line: 1, type: !6)
!30 = !DILocation(line: 1, column: 40, scope: !2)
!31 = !DILocalVariable(name: "value", scope: !2, file: !3, line: 3, type: !6)
!32 = !DILocation(line: 3, column: 9, scope: !2)
!33 = !DILocalVariable(name: "pc", scope: !2, file: !3, line: 4, type: !6)
!34 = !DILocation(line: 4, column: 9, scope: !2)
!35 = !DILocation(line: 5, column: 15, scope: !2)
!36 = !DILocation(line: 5, column: 20, scope: !2)
!37 = !DILocation(line: 5, column: 11, scope: !2)
!38 = !DILocation(line: 5, column: 5, scope: !2)
!39 = !DILabel(scope: !2, name: "increment", file: !3, line: 6, column: 1)
!40 = !DILocation(line: 6, column: 1, scope: !2)
!41 = !DILocation(line: 7, column: 11, scope: !2)
!42 = !DILocation(line: 8, column: 9, scope: !43)
!43 = distinct !DILexicalBlock(scope: !2, file: !3, line: 8, column: 9)
!44 = !DILocation(line: 8, column: 17, scope: !43)
!45 = !DILocation(line: 8, column: 14, scope: !43)
!46 = !DILocation(line: 8, column: 27, scope: !43)
!47 = !DILocation(line: 8, column: 20, scope: !43)
!48 = !DILocation(line: 9, column: 15, scope: !2)
!49 = !DILocation(line: 9, column: 20, scope: !2)
!50 = !DILocation(line: 9, column: 11, scope: !2)
!51 = !DILocation(line: 9, column: 5, scope: !2)
!52 = !DILabel(scope: !2, name: "double_it", file: !3, line: 10, column: 1)
!53 = !DILocation(line: 10, column: 1, scope: !2)
!54 = !DILocation(line: 11, column: 11, scope: !2)
!55 = !DILocation(line: 12, column: 9, scope: !56)
!56 = distinct !DILexicalBlock(scope: !2, file: !3, line: 12, column: 9)
!57 = !DILocation(line: 12, column: 17, scope: !56)
!58 = !DILocation(line: 12, column: 14, scope: !56)
!59 = !DILocation(line: 12, column: 27, scope: !56)
!60 = !DILocation(line: 12, column: 20, scope: !56)
!61 = !DILocation(line: 13, column: 15, scope: !2)
!62 = !DILocation(line: 13, column: 20, scope: !2)
!63 = !DILocation(line: 13, column: 11, scope: !2)
!64 = !DILocation(line: 13, column: 5, scope: !2)
!65 = !DILabel(scope: !2, name: "stop", file: !3, line: 14, column: 1)
!66 = !DILocation(line: 14, column: 1, scope: !2)
!67 = !DILocation(line: 15, column: 12, scope: !2)
!68 = !DILocation(line: 15, column: 5, scope: !2)
!69 = !DILocation(line: 16, column: 1, scope: !2)
!70 = distinct !DISubprogram(name: "main", scope: !3, file: !3, line: 18, type: !71, scopeLine: 18, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !10, retainedNodes: !13)
!71 = !DISubroutineType(types: !72)
!72 = !{!6}
!73 = !DILocalVariable(name: "program", scope: !70, file: !3, line: 19, type: !74)
!74 = !DICompositeType(tag: DW_TAG_array_type, baseType: !8, size: 40, elements: !75)
!75 = !{!76}
!76 = !DISubrange(count: 5)
!77 = !DILocation(line: 19, column: 25, scope: !70)
!78 = !DILocation(line: 20, column: 16, scope: !70)
!79 = !DILocation(line: 20, column: 12, scope: !70)
!80 = !DILocation(line: 20, column: 28, scope: !70)
!81 = !DILocation(line: 20, column: 5, scope: !70)
