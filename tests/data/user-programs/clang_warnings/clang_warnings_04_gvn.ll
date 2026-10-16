; ModuleID = '/workspace/out/clang_warnings_03_simplifycfg.ll'
source_filename = "/workspace/user-programs/clang_warnings.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@__const.last_of_four.four = private unnamed_addr constant [4 x i32] [i32 1, i32 2, i32 3, i32 4], align 16
@.str = private unnamed_addr constant [10 x i8] c"total %d\0A\00", align 1, !dbg !0
@.str.1 = private unnamed_addr constant [9 x i8] c"mean %d\0A\00", align 1, !dbg !7
@__const.main.values = private unnamed_addr constant [6 x i32] [i32 3, i32 -1, i32 4, i32 1, i32 -5, i32 9], align 16

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @count_set_bits(i32 noundef %value) #0 !dbg !25 {
entry:
    #dbg_value(i32 %value, !30, !DIExpression(), !31)
    #dbg_value(i32 0, !32, !DIExpression(), !31)
  br label %while.cond, !dbg !33

while.cond:                                       ; preds = %while.body, %entry
  %count.0 = phi i32 [ 0, %entry ], [ %add, %while.body ], !dbg !31
  %value.addr.0 = phi i32 [ %value, %entry ], [ %shr, %while.body ]
    #dbg_value(i32 %value.addr.0, !30, !DIExpression(), !31)
    #dbg_value(i32 %count.0, !32, !DIExpression(), !31)
  %and = and i32 %value.addr.0, 1, !dbg !34
    #dbg_value(i32 %and, !35, !DIExpression(), !31)
  %tobool.not = icmp eq i32 %and, 0, !dbg !33
  br i1 %tobool.not, label %while.end, label %while.body, !dbg !33

while.body:                                       ; preds = %while.cond
  %add = add i32 %count.0, %and, !dbg !36
    #dbg_value(i32 %add, !32, !DIExpression(), !31)
  %shr = lshr i32 %value.addr.0, 1, !dbg !38
    #dbg_value(i32 %shr, !30, !DIExpression(), !31)
  br label %while.cond, !dbg !33, !llvm.loop !39

while.end:                                        ; preds = %while.cond
  ret i32 %count.0, !dbg !42
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @sum_to(i32 noundef %limit) #0 !dbg !43 {
entry:
    #dbg_value(i32 %limit, !46, !DIExpression(), !47)
    #dbg_value(i32 0, !48, !DIExpression(), !47)
    #dbg_value(i32 0, !49, !DIExpression(), !51)
  br label %for.cond, !dbg !52

for.cond:                                         ; preds = %for.inc, %entry
  %total.0 = phi i32 [ 0, %entry ], [ %add1, %for.inc ], !dbg !47
  %i.0 = phi i32 [ 0, %entry ], [ %inc, %for.inc ], !dbg !53
    #dbg_value(i32 %i.0, !49, !DIExpression(), !51)
    #dbg_value(i32 %total.0, !48, !DIExpression(), !47)
  %cmp = icmp slt i32 %i.0, %limit, !dbg !54
  br i1 %cmp, label %for.inc, label %for.end, !dbg !56

for.inc:                                          ; preds = %for.cond
    #dbg_value(!DIArgList(i32 %total.0, i32 %i.0), !48, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_plus, DW_OP_stack_value), !47)
  %add1 = add nuw nsw i32 %total.0, %i.0, !dbg !57
    #dbg_value(i32 %add1, !48, !DIExpression(), !47)
  %inc = add nuw nsw i32 %i.0, 1, !dbg !59
    #dbg_value(i32 %inc, !49, !DIExpression(), !51)
  br label %for.cond, !dbg !60, !llvm.loop !61

for.end:                                          ; preds = %for.cond
  ret i32 %total.0, !dbg !63
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @is_same(i32 noundef %value) #0 !dbg !64 {
entry:
    #dbg_value(i32 %value, !65, !DIExpression(), !66)
  ret i32 1, !dbg !67
}

; Function Attrs: noinline nounwind uwtable
define dso_local zeroext i8 @small_constant() #0 !dbg !68 {
entry:
    #dbg_value(i8 44, !72, !DIExpression(), !73)
  ret i8 44, !dbg !74
}

; Function Attrs: noinline nounwind uwtable
define dso_local i64 @wide_shift(i32 noundef %value) #0 !dbg !75 {
entry:
    #dbg_value(i32 %value, !79, !DIExpression(), !80)
  ret i64 poison, !dbg !81
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @first_positive(ptr noundef %values, i32 noundef %count) #0 !dbg !82 {
entry:
    #dbg_value(ptr %values, !87, !DIExpression(), !88)
    #dbg_value(i32 %count, !89, !DIExpression(), !88)
    #dbg_value(i32 0, !90, !DIExpression(), !92)
  br label %for.cond, !dbg !93

for.cond:                                         ; preds = %for.inc, %entry
  %i.0 = phi i32 [ 0, %entry ], [ %inc, %for.inc ], !dbg !94
    #dbg_value(i32 %i.0, !90, !DIExpression(), !92)
  %cmp = icmp slt i32 %i.0, %count, !dbg !95
  br i1 %cmp, label %for.body, label %return, !dbg !97

for.body:                                         ; preds = %for.cond
  %idxprom = zext nneg i32 %i.0 to i64, !dbg !98
  %arrayidx = getelementptr inbounds nuw i32, ptr %values, i64 %idxprom, !dbg !98
  %0 = load i32, ptr %arrayidx, align 4, !dbg !98
  %cmp1 = icmp sgt i32 %0, 0, !dbg !101
    #dbg_value(i1 %cmp1, !102, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 32, DW_ATE_unsigned, DW_OP_stack_value), !88)
  br i1 %cmp1, label %if.then, label %for.inc, !dbg !103

if.then:                                          ; preds = %for.body
  br label %return, !dbg !104

for.inc:                                          ; preds = %for.body
  %inc = add nuw nsw i32 %i.0, 1, !dbg !106
    #dbg_value(i32 %inc, !90, !DIExpression(), !92)
  br label %for.cond, !dbg !107, !llvm.loop !108

return:                                           ; preds = %if.then, %for.cond
  %retval.0 = phi i32 [ %0, %if.then ], [ 0, %for.cond ], !dbg !88
  ret i32 %retval.0, !dbg !110
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @skip_empty(i32 noundef %value) #0 !dbg !111 {
entry:
    #dbg_value(i32 %value, !112, !DIExpression(), !113)
  %cmp = icmp sgt i32 %value, 10, !dbg !114
  ret i32 %value, !dbg !116
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @truncated_half() #0 !dbg !117 {
entry:
    #dbg_value(i32 2, !119, !DIExpression(), !120)
  ret i32 2, !dbg !121
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @last_of_four() #0 !dbg !122 {
entry:
    #dbg_declare(ptr @__const.last_of_four.four, !123, !DIExpression(), !127)
  ret i32 poison, !dbg !128
}

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @not_equal(i32 noundef %a, i32 noundef %b) #0 !dbg !129 {
entry:
    #dbg_value(i32 %a, !132, !DIExpression(), !133)
    #dbg_value(i32 %b, !134, !DIExpression(), !133)
  %tobool.not = icmp eq i32 %a, 0, !dbg !135
  %lnot.ext = zext i1 %tobool.not to i32, !dbg !135
  %cmp = icmp eq i32 %b, %lnot.ext, !dbg !137
  %. = select i1 %cmp, i32 1, i32 0, !dbg !133
  ret i32 %., !dbg !138
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @array_size(ptr noundef %values) #0 !dbg !139 {
entry:
    #dbg_value(ptr %values, !143, !DIExpression(), !144)
  ret i32 2, !dbg !145
}

; Function Attrs: noinline nounwind uwtable
define dso_local void @print_total(i64 noundef %total, double noundef %mean) #0 !dbg !146 {
entry:
    #dbg_value(i64 %total, !150, !DIExpression(), !151)
    #dbg_value(double %mean, !152, !DIExpression(), !151)
  %call = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i64 noundef %total) #3, !dbg !153
  %call1 = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.1, double noundef %mean) #3, !dbg !154
  ret void, !dbg !155
}

declare i32 @printf(ptr noundef, ...) #2

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @scaled_sum(ptr noundef %values, i32 noundef %count) #0 !dbg !156 {
entry:
    #dbg_value(ptr %values, !157, !DIExpression(), !158)
    #dbg_value(i32 %count, !159, !DIExpression(), !158)
    #dbg_value(i32 0, !160, !DIExpression(), !158)
    #dbg_value(i32 0, !161, !DIExpression(), !163)
  br label %for.cond, !dbg !164

for.cond:                                         ; preds = %for.body, %entry
  %total.0 = phi i32 [ 0, %entry ], [ %add, %for.body ], !dbg !158
  %i.0 = phi i32 [ 0, %entry ], [ %inc, %for.body ], !dbg !165
    #dbg_value(i32 %i.0, !161, !DIExpression(), !163)
    #dbg_value(i32 %total.0, !160, !DIExpression(), !158)
  %cmp = icmp slt i32 %i.0, %count, !dbg !166
  br i1 %cmp, label %for.body, label %for.end, !dbg !168

for.body:                                         ; preds = %for.cond
  %idxprom = zext nneg i32 %i.0 to i64, !dbg !169
  %arrayidx = getelementptr inbounds nuw i32, ptr %values, i64 %idxprom, !dbg !169
  %0 = load i32, ptr %arrayidx, align 4, !dbg !169
  %mul = shl nsw i32 %0, 1, !dbg !172
  %add = add nsw i32 %total.0, %mul, !dbg !173
    #dbg_value(i32 %add, !160, !DIExpression(), !158)
  %tobool.not = icmp eq i32 %add, 0, !dbg !174
  %inc = add nuw nsw i32 %i.0, 1, !dbg !175
    #dbg_value(i32 %inc, !161, !DIExpression(), !163)
  br label %for.cond, !dbg !176, !llvm.loop !177

for.end:                                          ; preds = %for.cond
  ret i32 %total.0, !dbg !179
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @clamp(i32 noundef %value) #0 !dbg !180 {
entry:
    #dbg_value(i32 %value, !181, !DIExpression(), !182)
    #dbg_value(i8 56, !183, !DIExpression(), !182)
    #dbg_value(i8 -56, !184, !DIExpression(), !182)
  %cmp = icmp slt i32 %value, 56, !dbg !185
  %retval.0 = select i1 %cmp, i32 56, i32 -56, !dbg !185
  ret i32 %retval.0, !dbg !187
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @max_of(ptr noundef %values, i32 noundef %count) #0 !dbg !188 {
entry:
    #dbg_value(ptr %values, !189, !DIExpression(), !190)
    #dbg_value(i32 %count, !191, !DIExpression(), !190)
  %0 = load i32, ptr %values, align 4, !dbg !192
    #dbg_value(i32 %0, !193, !DIExpression(), !190)
    #dbg_value(i32 1, !194, !DIExpression(), !196)
  br label %for.cond, !dbg !197

for.cond:                                         ; preds = %cond.end, %entry
  %best.0 = phi i32 [ %0, %entry ], [ %cond, %cond.end ], !dbg !190
  %i.0 = phi i32 [ 1, %entry ], [ %inc, %cond.end ], !dbg !198
    #dbg_value(i32 %i.0, !194, !DIExpression(), !196)
    #dbg_value(i32 %best.0, !193, !DIExpression(), !190)
  %cmp = icmp slt i32 %i.0, %count, !dbg !199
  br i1 %cmp, label %for.body, label %for.end, !dbg !201

for.body:                                         ; preds = %for.cond
  %idxprom = zext nneg i32 %i.0 to i64, !dbg !202
  %arrayidx1 = getelementptr inbounds nuw i32, ptr %values, i64 %idxprom, !dbg !202
  %1 = load i32, ptr %arrayidx1, align 4, !dbg !202
  %cmp2 = icmp sgt i32 %1, %best.0, !dbg !205
  br i1 %cmp2, label %cond.true, label %cond.end, !dbg !202

cond.true:                                        ; preds = %for.body
  br label %cond.end, !dbg !202

cond.end:                                         ; preds = %cond.true, %for.body
  %cond = phi i32 [ %1, %cond.true ], [ %best.0, %for.body ], !dbg !202
    #dbg_value(i32 %cond, !193, !DIExpression(), !190)
  %tobool.not = icmp eq i32 %cond, 0, !dbg !206
  %inc = add nuw nsw i32 %i.0, 1, !dbg !207
    #dbg_value(i32 %inc, !194, !DIExpression(), !196)
  br label %for.cond, !dbg !208, !llvm.loop !209

for.end:                                          ; preds = %for.cond
  ret i32 %best.0, !dbg !211
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @bump(i32 noundef %i) #0 !dbg !212 {
entry:
    #dbg_value(i32 %i, !213, !DIExpression(), !214)
    #dbg_value(i32 %i, !213, !DIExpression(DW_OP_plus_uconst, 1, DW_OP_stack_value), !214)
    #dbg_value(i32 %i, !213, !DIExpression(DW_OP_plus_uconst, 1, DW_OP_stack_value), !214)
  %add = add nsw i32 %i, 1, !dbg !215
    #dbg_value(i32 %add, !213, !DIExpression(), !214)
  ret i32 %add, !dbg !216
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @main() #0 !dbg !217 {
entry:
  %values = alloca [6 x i32], align 16
    #dbg_declare(ptr %values, !218, !DIExpression(), !222)
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(24) %values, ptr noundef nonnull align 16 dereferenceable(24) @__const.main.values, i64 24, i1 false), !dbg !222
  %call = call i32 @sum_to(i32 noundef 10), !dbg !223
  %conv = sext i32 %call to i64, !dbg !223
  call void @print_total(i64 noundef %conv, double noundef 2.500000e+00), !dbg !224
  %call1 = call i32 @first_positive(ptr noundef nonnull %values, i32 noundef 6), !dbg !225
  %call3 = call i32 @max_of(ptr noundef nonnull %values, i32 noundef 6), !dbg !226
  %add = add nsw i32 %call1, %call3, !dbg !227
  %call5 = call i32 @scaled_sum(ptr noundef nonnull %values, i32 noundef 6), !dbg !228
  %add6 = add nsw i32 %add, %call5, !dbg !229
  %arrayidx = getelementptr inbounds nuw i8, ptr %values, i64 20, !dbg !230
  %0 = load i32, ptr %arrayidx, align 4, !dbg !230
  %call7 = call i32 @clamp(i32 noundef %0), !dbg !231
  %add8 = add nsw i32 %add6, %call7, !dbg !232
  %call9 = call i32 @count_set_bits(i32 noundef 255), !dbg !233
  %add10 = add nsw i32 %add8, %call9, !dbg !234
  %call11 = call i32 @is_same(i32 noundef 1), !dbg !235
  %add12 = add nsw i32 %add10, %call11, !dbg !236
  %call13 = call zeroext i8 @small_constant(), !dbg !237
  %conv14 = zext i8 %call13 to i32, !dbg !237
  %add15 = add nsw i32 %add12, %conv14, !dbg !238
  %call16 = call i64 @wide_shift(i32 noundef 1), !dbg !239
  %conv17 = trunc i64 %call16 to i32, !dbg !240
  %add18 = add nsw i32 %add15, %conv17, !dbg !241
  %call19 = call i32 @skip_empty(i32 noundef 3), !dbg !242
  %add20 = add nsw i32 %add18, %call19, !dbg !243
  %call21 = call i32 @truncated_half(), !dbg !244
  %add22 = add nsw i32 %add20, %call21, !dbg !245
  %call23 = call i32 @last_of_four(), !dbg !246
  %add24 = add nsw i32 %add22, %call23, !dbg !247
  %call25 = call i32 @not_equal(i32 noundef 1, i32 noundef 2), !dbg !248
  %add26 = add nsw i32 %add24, %call25, !dbg !249
  %call28 = call i32 @array_size(ptr noundef nonnull %values), !dbg !250
  %add29 = add nsw i32 %add26, %call28, !dbg !251
  %call30 = call i32 @bump(i32 noundef 2), !dbg !252
  %add31 = add nsw i32 %add29, %call30, !dbg !253
  ret i32 %add31, !dbg !254
}

attributes #0 = { noinline nounwind uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }

!llvm.dbg.cu = !{!12}
!llvm.module.flags = !{!17, !18, !19, !20, !21, !22, !23}
!llvm.ident = !{!24}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(scope: null, file: !2, line: 73, type: !3, isLocal: true, isDefinition: true)
!2 = !DIFile(filename: "user-programs/clang_warnings.c", directory: "/workspace", checksumkind: CSK_MD5, checksum: "4220953798334ebd83620e81dd73d814")
!3 = !DICompositeType(tag: DW_TAG_array_type, baseType: !4, size: 80, elements: !5)
!4 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!5 = !{!6}
!6 = !DISubrange(count: 10)
!7 = !DIGlobalVariableExpression(var: !8, expr: !DIExpression())
!8 = distinct !DIGlobalVariable(scope: null, file: !2, line: 74, type: !9, isLocal: true, isDefinition: true)
!9 = !DICompositeType(tag: DW_TAG_array_type, baseType: !4, size: 72, elements: !10)
!10 = !{!11}
!11 = !DISubrange(count: 9)
!12 = distinct !DICompileUnit(language: DW_LANG_C11, file: !13, producer: "clang version 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, retainedTypes: !14, globals: !16, splitDebugInlining: false, nameTableKind: None)
!13 = !DIFile(filename: "/workspace/user-programs/clang_warnings.c", directory: "/workspace", checksumkind: CSK_MD5, checksum: "4220953798334ebd83620e81dd73d814")
!14 = !{!15}
!15 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!16 = !{!0, !7}
!17 = !{i32 7, !"Dwarf Version", i32 5}
!18 = !{i32 2, !"Debug Info Version", i32 3}
!19 = !{i32 1, !"wchar_size", i32 4}
!20 = !{i32 8, !"PIC Level", i32 2}
!21 = !{i32 7, !"PIE Level", i32 2}
!22 = !{i32 7, !"uwtable", i32 2}
!23 = !{i32 7, !"frame-pointer", i32 2}
!24 = !{!"clang version 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)"}
!25 = distinct !DISubprogram(name: "count_set_bits", scope: !2, file: !2, line: 4, type: !26, scopeLine: 4, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!26 = !DISubroutineType(types: !27)
!27 = !{!15, !28}
!28 = !DIBasicType(name: "unsigned int", size: 32, encoding: DW_ATE_unsigned)
!29 = !{}
!30 = !DILocalVariable(name: "value", arg: 1, scope: !25, file: !2, line: 4, type: !28)
!31 = !DILocation(line: 0, scope: !25)
!32 = !DILocalVariable(name: "count", scope: !25, file: !2, line: 5, type: !15)
!33 = !DILocation(line: 7, column: 5, scope: !25)
!34 = !DILocation(line: 7, column: 24, scope: !25)
!35 = !DILocalVariable(name: "bit", scope: !25, file: !2, line: 6, type: !28)
!36 = !DILocation(line: 8, column: 15, scope: !37)
!37 = distinct !DILexicalBlock(scope: !25, file: !2, line: 7, column: 30)
!38 = !DILocation(line: 9, column: 15, scope: !37)
!39 = distinct !{!39, !33, !40, !41}
!40 = !DILocation(line: 10, column: 5, scope: !25)
!41 = !{!"llvm.loop.mustprogress"}
!42 = !DILocation(line: 11, column: 5, scope: !25)
!43 = distinct !DISubprogram(name: "sum_to", scope: !2, file: !2, line: 14, type: !44, scopeLine: 14, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!44 = !DISubroutineType(types: !45)
!45 = !{!15, !15}
!46 = !DILocalVariable(name: "limit", arg: 1, scope: !43, file: !2, line: 14, type: !15)
!47 = !DILocation(line: 0, scope: !43)
!48 = !DILocalVariable(name: "total", scope: !43, file: !2, line: 15, type: !15)
!49 = !DILocalVariable(name: "i", scope: !50, file: !2, line: 16, type: !15)
!50 = distinct !DILexicalBlock(scope: !43, file: !2, line: 16, column: 5)
!51 = !DILocation(line: 0, scope: !50)
!52 = !DILocation(line: 16, column: 10, scope: !50)
!53 = !DILocation(line: 16, scope: !50)
!54 = !DILocation(line: 16, column: 23, scope: !55)
!55 = distinct !DILexicalBlock(scope: !50, file: !2, line: 16, column: 5)
!56 = !DILocation(line: 16, column: 5, scope: !50)
!57 = !DILocation(line: 18, column: 15, scope: !58)
!58 = distinct !DILexicalBlock(scope: !55, file: !2, line: 16, column: 37)
!59 = !DILocation(line: 16, column: 33, scope: !55)
!60 = !DILocation(line: 16, column: 5, scope: !55)
!61 = distinct !{!61, !56, !62, !41}
!62 = !DILocation(line: 19, column: 5, scope: !50)
!63 = !DILocation(line: 20, column: 5, scope: !43)
!64 = distinct !DISubprogram(name: "is_same", scope: !2, file: !2, line: 23, type: !44, scopeLine: 23, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!65 = !DILocalVariable(name: "value", arg: 1, scope: !64, file: !2, line: 23, type: !15)
!66 = !DILocation(line: 0, scope: !64)
!67 = !DILocation(line: 24, column: 5, scope: !64)
!68 = distinct !DISubprogram(name: "small_constant", scope: !2, file: !2, line: 27, type: !69, scopeLine: 27, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!69 = !DISubroutineType(types: !70)
!70 = !{!71}
!71 = !DIBasicType(name: "unsigned char", size: 8, encoding: DW_ATE_unsigned_char)
!72 = !DILocalVariable(name: "byte", scope: !68, file: !2, line: 28, type: !71)
!73 = !DILocation(line: 0, scope: !68)
!74 = !DILocation(line: 29, column: 5, scope: !68)
!75 = distinct !DISubprogram(name: "wide_shift", scope: !2, file: !2, line: 32, type: !76, scopeLine: 32, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!76 = !DISubroutineType(types: !77)
!77 = !{!78, !15}
!78 = !DIBasicType(name: "long", size: 64, encoding: DW_ATE_signed)
!79 = !DILocalVariable(name: "value", arg: 1, scope: !75, file: !2, line: 32, type: !15)
!80 = !DILocation(line: 0, scope: !75)
!81 = !DILocation(line: 33, column: 5, scope: !75)
!82 = distinct !DISubprogram(name: "first_positive", scope: !2, file: !2, line: 36, type: !83, scopeLine: 36, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!83 = !DISubroutineType(types: !84)
!84 = !{!15, !85, !15}
!85 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !86, size: 64)
!86 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !15)
!87 = !DILocalVariable(name: "values", arg: 1, scope: !82, file: !2, line: 36, type: !85)
!88 = !DILocation(line: 0, scope: !82)
!89 = !DILocalVariable(name: "count", arg: 2, scope: !82, file: !2, line: 36, type: !15)
!90 = !DILocalVariable(name: "i", scope: !91, file: !2, line: 38, type: !15)
!91 = distinct !DILexicalBlock(scope: !82, file: !2, line: 38, column: 5)
!92 = !DILocation(line: 0, scope: !91)
!93 = !DILocation(line: 38, column: 10, scope: !91)
!94 = !DILocation(line: 38, scope: !91)
!95 = !DILocation(line: 38, column: 23, scope: !96)
!96 = distinct !DILexicalBlock(scope: !91, file: !2, line: 38, column: 5)
!97 = !DILocation(line: 38, column: 5, scope: !91)
!98 = !DILocation(line: 39, column: 21, scope: !99)
!99 = distinct !DILexicalBlock(scope: !100, file: !2, line: 39, column: 13)
!100 = distinct !DILexicalBlock(scope: !96, file: !2, line: 38, column: 37)
!101 = !DILocation(line: 39, column: 31, scope: !99)
!102 = !DILocalVariable(name: "found", scope: !82, file: !2, line: 37, type: !15)
!103 = !DILocation(line: 39, column: 19, scope: !99)
!104 = !DILocation(line: 40, column: 13, scope: !105)
!105 = distinct !DILexicalBlock(scope: !99, file: !2, line: 39, column: 36)
!106 = !DILocation(line: 38, column: 33, scope: !96)
!107 = !DILocation(line: 38, column: 5, scope: !96)
!108 = distinct !{!108, !97, !109, !41}
!109 = !DILocation(line: 42, column: 5, scope: !91)
!110 = !DILocation(line: 44, column: 1, scope: !82)
!111 = distinct !DISubprogram(name: "skip_empty", scope: !2, file: !2, line: 46, type: !44, scopeLine: 46, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!112 = !DILocalVariable(name: "value", arg: 1, scope: !111, file: !2, line: 46, type: !15)
!113 = !DILocation(line: 0, scope: !111)
!114 = !DILocation(line: 47, column: 15, scope: !115)
!115 = distinct !DILexicalBlock(scope: !111, file: !2, line: 47, column: 9)
!116 = !DILocation(line: 48, column: 5, scope: !111)
!117 = distinct !DISubprogram(name: "truncated_half", scope: !2, file: !2, line: 51, type: !118, scopeLine: 51, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!118 = !DISubroutineType(types: !14)
!119 = !DILocalVariable(name: "half", scope: !117, file: !2, line: 52, type: !15)
!120 = !DILocation(line: 0, scope: !117)
!121 = !DILocation(line: 53, column: 5, scope: !117)
!122 = distinct !DISubprogram(name: "last_of_four", scope: !2, file: !2, line: 56, type: !118, scopeLine: 56, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!123 = !DILocalVariable(name: "four", scope: !122, file: !2, line: 57, type: !124)
!124 = !DICompositeType(tag: DW_TAG_array_type, baseType: !15, size: 128, elements: !125)
!125 = !{!126}
!126 = !DISubrange(count: 4)
!127 = !DILocation(line: 57, column: 9, scope: !122)
!128 = !DILocation(line: 58, column: 5, scope: !122)
!129 = distinct !DISubprogram(name: "not_equal", scope: !2, file: !2, line: 61, type: !130, scopeLine: 61, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!130 = !DISubroutineType(types: !131)
!131 = !{!15, !15, !15}
!132 = !DILocalVariable(name: "a", arg: 1, scope: !129, file: !2, line: 61, type: !15)
!133 = !DILocation(line: 0, scope: !129)
!134 = !DILocalVariable(name: "b", arg: 2, scope: !129, file: !2, line: 61, type: !15)
!135 = !DILocation(line: 62, column: 9, scope: !136)
!136 = distinct !DILexicalBlock(scope: !129, file: !2, line: 62, column: 9)
!137 = !DILocation(line: 62, column: 12, scope: !136)
!138 = !DILocation(line: 66, column: 1, scope: !129)
!139 = distinct !DISubprogram(name: "array_size", scope: !2, file: !2, line: 68, type: !140, scopeLine: 68, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!140 = !DISubroutineType(types: !141)
!141 = !{!15, !142}
!142 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !15, size: 64)
!143 = !DILocalVariable(name: "values", arg: 1, scope: !139, file: !2, line: 68, type: !142)
!144 = !DILocation(line: 0, scope: !139)
!145 = !DILocation(line: 69, column: 5, scope: !139)
!146 = distinct !DISubprogram(name: "print_total", scope: !2, file: !2, line: 72, type: !147, scopeLine: 72, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!147 = !DISubroutineType(types: !148)
!148 = !{null, !78, !149}
!149 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!150 = !DILocalVariable(name: "total", arg: 1, scope: !146, file: !2, line: 72, type: !78)
!151 = !DILocation(line: 0, scope: !146)
!152 = !DILocalVariable(name: "mean", arg: 2, scope: !146, file: !2, line: 72, type: !149)
!153 = !DILocation(line: 73, column: 5, scope: !146)
!154 = !DILocation(line: 74, column: 5, scope: !146)
!155 = !DILocation(line: 75, column: 1, scope: !146)
!156 = distinct !DISubprogram(name: "scaled_sum", scope: !2, file: !2, line: 77, type: !83, scopeLine: 77, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!157 = !DILocalVariable(name: "values", arg: 1, scope: !156, file: !2, line: 77, type: !85)
!158 = !DILocation(line: 0, scope: !156)
!159 = !DILocalVariable(name: "count", arg: 2, scope: !156, file: !2, line: 77, type: !15)
!160 = !DILocalVariable(name: "total", scope: !156, file: !2, line: 78, type: !15)
!161 = !DILocalVariable(name: "i", scope: !162, file: !2, line: 79, type: !15)
!162 = distinct !DILexicalBlock(scope: !156, file: !2, line: 79, column: 5)
!163 = !DILocation(line: 0, scope: !162)
!164 = !DILocation(line: 79, column: 10, scope: !162)
!165 = !DILocation(line: 79, scope: !162)
!166 = !DILocation(line: 79, column: 23, scope: !167)
!167 = distinct !DILexicalBlock(scope: !162, file: !2, line: 79, column: 5)
!168 = !DILocation(line: 79, column: 5, scope: !162)
!169 = !DILocation(line: 80, column: 29, scope: !170)
!170 = distinct !DILexicalBlock(scope: !171, file: !2, line: 80, column: 13)
!171 = distinct !DILexicalBlock(scope: !167, file: !2, line: 79, column: 37)
!172 = !DILocation(line: 80, column: 39, scope: !170)
!173 = !DILocation(line: 80, column: 27, scope: !170)
!174 = !DILocation(line: 80, column: 19, scope: !170)
!175 = !DILocation(line: 79, column: 33, scope: !167)
!176 = !DILocation(line: 79, column: 5, scope: !167)
!177 = distinct !{!177, !168, !178, !41}
!178 = !DILocation(line: 83, column: 5, scope: !162)
!179 = !DILocation(line: 84, column: 5, scope: !156)
!180 = distinct !DISubprogram(name: "clamp", scope: !2, file: !2, line: 87, type: !44, scopeLine: 87, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!181 = !DILocalVariable(name: "value", arg: 1, scope: !180, file: !2, line: 87, type: !15)
!182 = !DILocation(line: 0, scope: !180)
!183 = !DILocalVariable(name: "low", scope: !180, file: !2, line: 88, type: !4)
!184 = !DILocalVariable(name: "high", scope: !180, file: !2, line: 89, type: !4)
!185 = !DILocation(line: 90, column: 15, scope: !186)
!186 = distinct !DILexicalBlock(scope: !180, file: !2, line: 90, column: 9)
!187 = !DILocation(line: 97, column: 1, scope: !180)
!188 = distinct !DISubprogram(name: "max_of", scope: !2, file: !2, line: 99, type: !83, scopeLine: 99, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!189 = !DILocalVariable(name: "values", arg: 1, scope: !188, file: !2, line: 99, type: !85)
!190 = !DILocation(line: 0, scope: !188)
!191 = !DILocalVariable(name: "count", arg: 2, scope: !188, file: !2, line: 99, type: !15)
!192 = !DILocation(line: 100, column: 16, scope: !188)
!193 = !DILocalVariable(name: "best", scope: !188, file: !2, line: 100, type: !15)
!194 = !DILocalVariable(name: "i", scope: !195, file: !2, line: 101, type: !15)
!195 = distinct !DILexicalBlock(scope: !188, file: !2, line: 101, column: 5)
!196 = !DILocation(line: 0, scope: !195)
!197 = !DILocation(line: 101, column: 10, scope: !195)
!198 = !DILocation(line: 101, scope: !195)
!199 = !DILocation(line: 101, column: 23, scope: !200)
!200 = distinct !DILexicalBlock(scope: !195, file: !2, line: 101, column: 5)
!201 = !DILocation(line: 101, column: 5, scope: !195)
!202 = !DILocation(line: 102, column: 20, scope: !203)
!203 = distinct !DILexicalBlock(scope: !204, file: !2, line: 102, column: 13)
!204 = distinct !DILexicalBlock(scope: !200, file: !2, line: 101, column: 37)
!205 = !DILocation(line: 102, column: 30, scope: !203)
!206 = !DILocation(line: 102, column: 18, scope: !203)
!207 = !DILocation(line: 101, column: 33, scope: !200)
!208 = !DILocation(line: 101, column: 5, scope: !200)
!209 = distinct !{!209, !201, !210, !41}
!210 = !DILocation(line: 105, column: 5, scope: !195)
!211 = !DILocation(line: 106, column: 5, scope: !188)
!212 = distinct !DISubprogram(name: "bump", scope: !2, file: !2, line: 109, type: !44, scopeLine: 109, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!213 = !DILocalVariable(name: "i", arg: 1, scope: !212, file: !2, line: 109, type: !15)
!214 = !DILocation(line: 0, scope: !212)
!215 = !DILocation(line: 110, column: 13, scope: !212)
!216 = !DILocation(line: 111, column: 5, scope: !212)
!217 = distinct !DISubprogram(name: "main", scope: !2, file: !2, line: 114, type: !118, scopeLine: 114, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !12, retainedNodes: !29)
!218 = !DILocalVariable(name: "values", scope: !217, file: !2, line: 115, type: !219)
!219 = !DICompositeType(tag: DW_TAG_array_type, baseType: !15, size: 192, elements: !220)
!220 = !{!221}
!221 = !DISubrange(count: 6)
!222 = !DILocation(line: 115, column: 9, scope: !217)
!223 = !DILocation(line: 116, column: 17, scope: !217)
!224 = !DILocation(line: 116, column: 5, scope: !217)
!225 = !DILocation(line: 117, column: 12, scope: !217)
!226 = !DILocation(line: 117, column: 40, scope: !217)
!227 = !DILocation(line: 117, column: 38, scope: !217)
!228 = !DILocation(line: 117, column: 60, scope: !217)
!229 = !DILocation(line: 117, column: 58, scope: !217)
!230 = !DILocation(line: 117, column: 90, scope: !217)
!231 = !DILocation(line: 117, column: 84, scope: !217)
!232 = !DILocation(line: 117, column: 82, scope: !217)
!233 = !DILocation(line: 118, column: 11, scope: !217)
!234 = !DILocation(line: 118, column: 9, scope: !217)
!235 = !DILocation(line: 118, column: 34, scope: !217)
!236 = !DILocation(line: 118, column: 32, scope: !217)
!237 = !DILocation(line: 118, column: 47, scope: !217)
!238 = !DILocation(line: 118, column: 45, scope: !217)
!239 = !DILocation(line: 118, column: 71, scope: !217)
!240 = !DILocation(line: 118, column: 66, scope: !217)
!241 = !DILocation(line: 118, column: 64, scope: !217)
!242 = !DILocation(line: 118, column: 87, scope: !217)
!243 = !DILocation(line: 118, column: 85, scope: !217)
!244 = !DILocation(line: 119, column: 11, scope: !217)
!245 = !DILocation(line: 119, column: 9, scope: !217)
!246 = !DILocation(line: 119, column: 30, scope: !217)
!247 = !DILocation(line: 119, column: 28, scope: !217)
!248 = !DILocation(line: 119, column: 47, scope: !217)
!249 = !DILocation(line: 119, column: 45, scope: !217)
!250 = !DILocation(line: 119, column: 65, scope: !217)
!251 = !DILocation(line: 119, column: 63, scope: !217)
!252 = !DILocation(line: 119, column: 86, scope: !217)
!253 = !DILocation(line: 119, column: 84, scope: !217)
!254 = !DILocation(line: 117, column: 5, scope: !217)
