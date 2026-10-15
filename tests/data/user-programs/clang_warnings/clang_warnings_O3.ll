; ModuleID = '/workspace/user-programs/clang_warnings.c'
source_filename = "/workspace/user-programs/clang_warnings.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@.str = private unnamed_addr constant [10 x i8] c"total %d\0A\00", align 1, !dbg !0
@.str.1 = private unnamed_addr constant [9 x i8] c"mean %d\0A\00", align 1, !dbg !7

; Function Attrs: nofree norecurse nosync nounwind memory(none) uwtable
define dso_local i32 @count_set_bits(i32 noundef %value) local_unnamed_addr #0 !dbg !29 {
entry:
    #dbg_value(i32 %value, !34, !DIExpression(), !37)
    #dbg_value(i32 0, !35, !DIExpression(), !37)
  %and3 = and i32 %value, 1, !dbg !38
  %tobool.not4 = icmp eq i32 %and3, 0, !dbg !39
  br i1 %tobool.not4, label %while.end, label %while.body, !dbg !40

while.body:                                       ; preds = %entry, %while.body
  %value.addr.06 = phi i32 [ %shr, %while.body ], [ %value, %entry ]
  %count.05 = phi i32 [ %add, %while.body ], [ 0, %entry ]
    #dbg_value(i32 %value.addr.06, !34, !DIExpression(), !37)
    #dbg_value(i32 %count.05, !35, !DIExpression(), !37)
  %add = add i32 %count.05, 1, !dbg !41
    #dbg_value(i32 %add, !35, !DIExpression(), !37)
  %shr = lshr i32 %value.addr.06, 1, !dbg !43
    #dbg_value(i32 %shr, !34, !DIExpression(), !37)
    #dbg_value(i32 %shr, !36, !DIExpression(DW_OP_constu, 1, DW_OP_and, DW_OP_stack_value), !37)
  %0 = and i32 %value.addr.06, 2, !dbg !44
  %tobool.not = icmp eq i32 %0, 0, !dbg !44
  br i1 %tobool.not, label %while.end, label %while.body, !dbg !45, !llvm.loop !46

while.end:                                        ; preds = %while.body, %entry
  %count.0.lcssa = phi i32 [ 0, %entry ], [ %add, %while.body ], !dbg !37
  ret i32 %count.0.lcssa, !dbg !50
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local i32 @sum_to(i32 noundef %limit) local_unnamed_addr #1 !dbg !51 {
entry:
    #dbg_value(i32 %limit, !55, !DIExpression(), !59)
    #dbg_value(i32 0, !56, !DIExpression(), !59)
    #dbg_value(i32 0, !57, !DIExpression(), !60)
  %cmp7 = icmp sgt i32 %limit, 0, !dbg !61
  br i1 %cmp7, label %for.body.preheader, label %for.cond.cleanup, !dbg !63

for.body.preheader:                               ; preds = %entry
    #dbg_value(i32 poison, !57, !DIExpression(), !60)
    #dbg_value(i32 poison, !56, !DIExpression(), !59)
  %0 = add nsw i32 %limit, -1, !dbg !64
  %1 = zext nneg i32 %0 to i33, !dbg !64
  %2 = add nsw i32 %limit, -2, !dbg !64
  %3 = zext i32 %2 to i33, !dbg !64
  %4 = mul i33 %1, %3, !dbg !64
  %5 = lshr i33 %4, 1, !dbg !64
  %6 = trunc nuw i33 %5 to i32, !dbg !64
  %7 = add i32 %limit, %6, !dbg !64
  %8 = add i32 %7, -1, !dbg !64
  br label %for.cond.cleanup, !dbg !65

for.cond.cleanup:                                 ; preds = %for.body.preheader, %entry
  %total.0.lcssa = phi i32 [ 0, %entry ], [ %8, %for.body.preheader ], !dbg !59
  ret i32 %total.0.lcssa, !dbg !65
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local noundef i32 @is_same(i32 noundef %value) local_unnamed_addr #1 !dbg !66 {
entry:
    #dbg_value(i32 %value, !68, !DIExpression(), !69)
  ret i32 1, !dbg !70
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local noundef zeroext i8 @small_constant() local_unnamed_addr #1 !dbg !71 {
entry:
    #dbg_value(i8 44, !76, !DIExpression(), !77)
  ret i8 44, !dbg !78
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local i64 @wide_shift(i32 noundef %value) local_unnamed_addr #1 !dbg !79 {
entry:
    #dbg_value(i32 %value, !84, !DIExpression(), !85)
  ret i64 poison, !dbg !86
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local range(i32 0, -2147483648) i32 @first_positive(ptr noundef readonly captures(none) %values, i32 noundef %count) local_unnamed_addr #2 !dbg !87 {
entry:
    #dbg_value(ptr %values, !93, !DIExpression(), !98)
    #dbg_value(i32 %count, !94, !DIExpression(), !98)
    #dbg_value(i32 0, !96, !DIExpression(), !99)
  %cmp.not9 = icmp sgt i32 %count, 0, !dbg !100
  br i1 %cmp.not9, label %for.body.preheader, label %cleanup, !dbg !102

for.body.preheader:                               ; preds = %entry
  %wide.trip.count = zext nneg i32 %count to i64, !dbg !103
  br label %for.body, !dbg !104

for.cond:                                         ; preds = %for.body
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !105
    #dbg_value(i64 %indvars.iv.next, !96, !DIExpression(), !99)
  %exitcond.not = icmp eq i64 %indvars.iv.next, %wide.trip.count, !dbg !103
  br i1 %exitcond.not, label %cleanup, label %for.body, !dbg !106, !llvm.loop !107

for.body:                                         ; preds = %for.body.preheader, %for.cond
  %indvars.iv = phi i64 [ 0, %for.body.preheader ], [ %indvars.iv.next, %for.cond ]
    #dbg_value(i64 %indvars.iv, !96, !DIExpression(), !99)
  %arrayidx = getelementptr inbounds nuw i32, ptr %values, i64 %indvars.iv, !dbg !109
  %0 = load i32, ptr %arrayidx, align 4, !dbg !109, !tbaa !25
  %cmp1 = icmp sgt i32 %0, 0, !dbg !112
    #dbg_value(i1 %cmp1, !95, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 32, DW_ATE_unsigned, DW_OP_stack_value), !98)
    #dbg_value(i64 %indvars.iv, !96, !DIExpression(DW_OP_plus_uconst, 1, DW_OP_stack_value), !99)
  br i1 %cmp1, label %cleanup, label %for.cond, !dbg !113

cleanup:                                          ; preds = %for.cond, %for.body, %entry
  %spec.select = phi i32 [ 0, %entry ], [ %0, %for.body ], [ 0, %for.cond ]
  ret i32 %spec.select, !dbg !114
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local noundef i32 @skip_empty(i32 noundef returned %value) local_unnamed_addr #1 !dbg !115 {
entry:
    #dbg_value(i32 %value, !117, !DIExpression(), !118)
  ret i32 %value, !dbg !119
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local noundef i32 @truncated_half() local_unnamed_addr #1 !dbg !120 {
entry:
    #dbg_value(i32 2, !123, !DIExpression(), !124)
  ret i32 2, !dbg !125
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local i32 @last_of_four() local_unnamed_addr #1 !dbg !126 {
entry:
    #dbg_assign(i1 poison, !128, !DIExpression(), !132, ptr poison, !DIExpression(), !133)
    #dbg_assign(i1 poison, !128, !DIExpression(), !134, ptr poison, !DIExpression(), !133)
  ret i32 poison, !dbg !135
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local range(i32 0, 2) i32 @not_equal(i32 noundef %a, i32 noundef %b) local_unnamed_addr #1 !dbg !136 {
entry:
    #dbg_value(i32 %a, !140, !DIExpression(), !142)
    #dbg_value(i32 %b, !141, !DIExpression(), !142)
  %tobool.not = icmp eq i32 %a, 0, !dbg !143
  %lnot.ext = zext i1 %tobool.not to i32, !dbg !143
  %cmp = icmp eq i32 %b, %lnot.ext, !dbg !145
  %. = zext i1 %cmp to i32, !dbg !142
  ret i32 %., !dbg !146
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local noundef i32 @array_size(ptr noundef readnone captures(none) %values) local_unnamed_addr #1 !dbg !147 {
entry:
    #dbg_value(ptr %values, !152, !DIExpression(), !153)
  ret i32 2, !dbg !154
}

; Function Attrs: nofree nounwind uwtable
define dso_local void @print_total(i64 noundef %total, double noundef %mean) local_unnamed_addr #3 !dbg !155 {
entry:
    #dbg_value(i64 %total, !160, !DIExpression(), !162)
    #dbg_value(double %mean, !161, !DIExpression(), !162)
  %call = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i64 noundef %total), !dbg !163
  %call1 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.1, double noundef %mean), !dbg !164
  ret void, !dbg !165
}

; Function Attrs: nofree nounwind
declare !dbg !166 noundef i32 @printf(ptr noundef readonly captures(none), ...) local_unnamed_addr #4

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @scaled_sum(ptr noundef readonly captures(none) %values, i32 noundef %count) local_unnamed_addr #2 !dbg !173 {
entry:
    #dbg_value(ptr %values, !175, !DIExpression(), !180)
    #dbg_value(i32 %count, !176, !DIExpression(), !180)
    #dbg_value(i32 0, !177, !DIExpression(), !180)
    #dbg_value(i32 0, !178, !DIExpression(), !181)
  %cmp6 = icmp sgt i32 %count, 0, !dbg !182
  br i1 %cmp6, label %for.body.preheader, label %for.cond.cleanup, !dbg !184

for.body.preheader:                               ; preds = %entry
  %wide.trip.count = zext nneg i32 %count to i64, !dbg !185
  %min.iters.check = icmp ult i32 %count, 8, !dbg !186
  br i1 %min.iters.check, label %for.body.preheader12, label %vector.ph, !dbg !186

vector.ph:                                        ; preds = %for.body.preheader
  %n.vec = and i64 %wide.trip.count, 2147483640
  br label %vector.body, !dbg !186

vector.body:                                      ; preds = %vector.body, %vector.ph
  %index = phi i64 [ 0, %vector.ph ], [ %index.next, %vector.body ], !dbg !187
  %vec.phi = phi <4 x i32> [ zeroinitializer, %vector.ph ], [ %4, %vector.body ]
  %vec.phi10 = phi <4 x i32> [ zeroinitializer, %vector.ph ], [ %5, %vector.body ]
  %0 = getelementptr inbounds nuw i32, ptr %values, i64 %index, !dbg !188
  %1 = getelementptr inbounds nuw i8, ptr %0, i64 16, !dbg !188
  %wide.load = load <4 x i32>, ptr %0, align 4, !dbg !188, !tbaa !25
  %wide.load11 = load <4 x i32>, ptr %1, align 4, !dbg !188, !tbaa !25
  %2 = shl nsw <4 x i32> %wide.load, splat (i32 1), !dbg !191
  %3 = shl nsw <4 x i32> %wide.load11, splat (i32 1), !dbg !191
  %4 = add <4 x i32> %2, %vec.phi, !dbg !192
  %5 = add <4 x i32> %3, %vec.phi10, !dbg !192
  %index.next = add nuw i64 %index, 8, !dbg !187
  %6 = icmp eq i64 %index.next, %n.vec, !dbg !193
  br i1 %6, label %middle.block, label %vector.body, !dbg !193, !llvm.loop !194

middle.block:                                     ; preds = %vector.body
  %bin.rdx = add <4 x i32> %5, %4, !dbg !193
  %7 = tail call i32 @llvm.vector.reduce.add.v4i32(<4 x i32> %bin.rdx), !dbg !193
  %cmp.n = icmp eq i64 %n.vec, %wide.trip.count, !dbg !193
  br i1 %cmp.n, label %for.cond.cleanup, label %for.body.preheader12, !dbg !193

for.body.preheader12:                             ; preds = %for.body.preheader, %middle.block
  %indvars.iv.ph = phi i64 [ 0, %for.body.preheader ], [ %n.vec, %middle.block ]
  %total.07.ph = phi i32 [ 0, %for.body.preheader ], [ %7, %middle.block ]
  br label %for.body, !dbg !193

for.cond.cleanup:                                 ; preds = %for.body, %middle.block, %entry
  %total.0.lcssa = phi i32 [ 0, %entry ], [ %7, %middle.block ], [ %add, %for.body ], !dbg !180
  ret i32 %total.0.lcssa, !dbg !197

for.body:                                         ; preds = %for.body.preheader12, %for.body
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.body ], [ %indvars.iv.ph, %for.body.preheader12 ]
  %total.07 = phi i32 [ %add, %for.body ], [ %total.07.ph, %for.body.preheader12 ]
    #dbg_value(i64 %indvars.iv, !178, !DIExpression(), !181)
    #dbg_value(i32 %total.07, !177, !DIExpression(), !180)
  %arrayidx = getelementptr inbounds nuw i32, ptr %values, i64 %indvars.iv, !dbg !188
  %8 = load i32, ptr %arrayidx, align 4, !dbg !188, !tbaa !25
  %mul = shl nsw i32 %8, 1, !dbg !191
  %add = add nsw i32 %mul, %total.07, !dbg !192
    #dbg_value(i32 %add, !177, !DIExpression(), !180)
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !187
    #dbg_value(i64 %indvars.iv.next, !178, !DIExpression(), !181)
  %exitcond.not = icmp eq i64 %indvars.iv.next, %wide.trip.count, !dbg !185
  br i1 %exitcond.not, label %for.cond.cleanup, label %for.body, !dbg !193, !llvm.loop !198
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local noundef range(i32 -56, 57) i32 @clamp(i32 noundef %value) local_unnamed_addr #1 !dbg !199 {
entry:
    #dbg_value(i32 %value, !201, !DIExpression(), !204)
    #dbg_value(i8 56, !202, !DIExpression(), !204)
    #dbg_value(i8 -56, !203, !DIExpression(), !204)
  %cmp = icmp slt i32 %value, 56, !dbg !205
  %retval.0 = select i1 %cmp, i32 56, i32 -56, !dbg !207
  ret i32 %retval.0, !dbg !208
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @max_of(ptr noundef readonly captures(none) %values, i32 noundef %count) local_unnamed_addr #2 !dbg !209 {
entry:
    #dbg_value(ptr %values, !211, !DIExpression(), !216)
    #dbg_value(i32 %count, !212, !DIExpression(), !216)
  %0 = load i32, ptr %values, align 4, !dbg !217, !tbaa !25
    #dbg_value(i32 %0, !213, !DIExpression(), !216)
    #dbg_value(i32 1, !214, !DIExpression(), !218)
  %cmp18 = icmp sgt i32 %count, 1, !dbg !219
  br i1 %cmp18, label %for.body.preheader, label %for.cond.cleanup, !dbg !221

for.body.preheader:                               ; preds = %entry
  %wide.trip.count = zext nneg i32 %count to i64, !dbg !222
  %1 = add nsw i64 %wide.trip.count, -1, !dbg !223
  %min.iters.check = icmp ult i32 %count, 9, !dbg !223
  br i1 %min.iters.check, label %for.body.preheader24, label %vector.ph, !dbg !223

vector.ph:                                        ; preds = %for.body.preheader
  %n.vec = and i64 %1, -8
  %2 = or disjoint i64 %n.vec, 1
  %broadcast.splatinsert = insertelement <4 x i32> poison, i32 %0, i64 0
  %broadcast.splat = shufflevector <4 x i32> %broadcast.splatinsert, <4 x i32> poison, <4 x i32> zeroinitializer
  br label %vector.body, !dbg !223

vector.body:                                      ; preds = %vector.body, %vector.ph
  %index = phi i64 [ 0, %vector.ph ], [ %index.next, %vector.body ]
  %vec.phi = phi <4 x i32> [ %broadcast.splat, %vector.ph ], [ %6, %vector.body ]
  %vec.phi22 = phi <4 x i32> [ %broadcast.splat, %vector.ph ], [ %7, %vector.body ]
  %3 = getelementptr inbounds nuw i32, ptr %values, i64 %index, !dbg !224
  %4 = getelementptr inbounds nuw i8, ptr %3, i64 4, !dbg !224
  %5 = getelementptr inbounds nuw i8, ptr %3, i64 20, !dbg !224
  %wide.load = load <4 x i32>, ptr %4, align 4, !dbg !224, !tbaa !25
  %wide.load23 = load <4 x i32>, ptr %5, align 4, !dbg !224, !tbaa !25
  %6 = tail call <4 x i32> @llvm.smax.v4i32(<4 x i32> %wide.load, <4 x i32> %vec.phi), !dbg !224
  %7 = tail call <4 x i32> @llvm.smax.v4i32(<4 x i32> %wide.load23, <4 x i32> %vec.phi22), !dbg !224
  %index.next = add nuw i64 %index, 8
  %8 = icmp eq i64 %index.next, %n.vec, !dbg !227
  br i1 %8, label %middle.block, label %vector.body, !dbg !227, !llvm.loop !228

middle.block:                                     ; preds = %vector.body
  %rdx.minmax = tail call <4 x i32> @llvm.smax.v4i32(<4 x i32> %6, <4 x i32> %7), !dbg !227
  %9 = tail call i32 @llvm.vector.reduce.smax.v4i32(<4 x i32> %rdx.minmax), !dbg !227
  %cmp.n = icmp eq i64 %1, %n.vec, !dbg !227
  br i1 %cmp.n, label %for.cond.cleanup, label %for.body.preheader24, !dbg !227

for.body.preheader24:                             ; preds = %for.body.preheader, %middle.block
  %indvars.iv.ph = phi i64 [ 1, %for.body.preheader ], [ %2, %middle.block ]
  %best.019.ph = phi i32 [ %0, %for.body.preheader ], [ %9, %middle.block ]
  br label %for.body, !dbg !227

for.cond.cleanup:                                 ; preds = %for.body, %middle.block, %entry
  %best.0.lcssa = phi i32 [ %0, %entry ], [ %9, %middle.block ], [ %.best.0, %for.body ], !dbg !216
  ret i32 %best.0.lcssa, !dbg !229

for.body:                                         ; preds = %for.body.preheader24, %for.body
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.body ], [ %indvars.iv.ph, %for.body.preheader24 ]
  %best.019 = phi i32 [ %.best.0, %for.body ], [ %best.019.ph, %for.body.preheader24 ]
    #dbg_value(i64 %indvars.iv, !214, !DIExpression(), !218)
    #dbg_value(i32 %best.019, !213, !DIExpression(), !216)
  %arrayidx1 = getelementptr inbounds nuw i32, ptr %values, i64 %indvars.iv, !dbg !224
  %10 = load i32, ptr %arrayidx1, align 4, !dbg !224, !tbaa !25
  %.best.0 = tail call i32 @llvm.smax.i32(i32 %10, i32 %best.019), !dbg !224
    #dbg_value(i32 %.best.0, !213, !DIExpression(), !216)
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !230
    #dbg_value(i64 %indvars.iv.next, !214, !DIExpression(), !218)
  %exitcond.not = icmp eq i64 %indvars.iv.next, %wide.trip.count, !dbg !222
  br i1 %exitcond.not, label %for.cond.cleanup, label %for.body, !dbg !227, !llvm.loop !231
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local range(i32 -2147483647, -2147483648) i32 @bump(i32 noundef %i) local_unnamed_addr #1 !dbg !232 {
entry:
    #dbg_value(i32 %i, !234, !DIExpression(), !235)
    #dbg_value(i32 %i, !234, !DIExpression(DW_OP_plus_uconst, 1, DW_OP_stack_value), !235)
  %add = add nsw i32 %i, 1, !dbg !236
    #dbg_value(i32 %add, !234, !DIExpression(), !235)
  ret i32 %add, !dbg !237
}

; Function Attrs: nofree nounwind uwtable
define dso_local i32 @main() local_unnamed_addr #3 !dbg !238 {
entry:
    #dbg_assign(i1 poison, !240, !DIExpression(), !244, ptr poison, !DIExpression(), !245)
    #dbg_assign(i1 poison, !240, !DIExpression(), !246, ptr poison, !DIExpression(), !245)
    #dbg_value(i64 45, !160, !DIExpression(), !247)
    #dbg_value(double 2.500000e+00, !161, !DIExpression(), !247)
  %call.i = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i64 noundef 45), !dbg !249
  %call1.i = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.1, double noundef 2.500000e+00), !dbg !250
  ret i32 undef, !dbg !251
}

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smax.i32(i32, i32) #5

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.vector.reduce.add.v4i32(<4 x i32>) #6

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare <4 x i32> @llvm.smax.v4i32(<4 x i32>, <4 x i32>) #5

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.vector.reduce.smax.v4i32(<4 x i32>) #6

attributes #0 = { nofree norecurse nosync nounwind memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree norecurse nosync nounwind memory(argmem: read) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { nofree nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #5 = { nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none) }
attributes #6 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }

!llvm.dbg.cu = !{!12}
!llvm.module.flags = !{!17, !18, !19, !20, !21, !22, !23}
!llvm.ident = !{!24}
!llvm.errno.tbaa = !{!25}

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
!12 = distinct !DICompileUnit(language: DW_LANG_C11, file: !13, producer: "clang version 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, retainedTypes: !14, globals: !16, splitDebugInlining: false, nameTableKind: None)
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
!23 = !{i32 7, !"debug-info-assignment-tracking", i1 true}
!24 = !{!"clang version 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)"}
!25 = !{!26, !26, i64 0}
!26 = !{!"int", !27, i64 0}
!27 = !{!"omnipotent char", !28, i64 0}
!28 = !{!"Simple C/C++ TBAA"}
!29 = distinct !DISubprogram(name: "count_set_bits", scope: !2, file: !2, line: 4, type: !30, scopeLine: 4, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !12, retainedNodes: !33, keyInstructions: true)
!30 = !DISubroutineType(types: !31)
!31 = !{!15, !32}
!32 = !DIBasicType(name: "unsigned int", size: 32, encoding: DW_ATE_unsigned)
!33 = !{!34, !35, !36}
!34 = !DILocalVariable(name: "value", arg: 1, scope: !29, file: !2, line: 4, type: !32)
!35 = !DILocalVariable(name: "count", scope: !29, file: !2, line: 5, type: !15)
!36 = !DILocalVariable(name: "bit", scope: !29, file: !2, line: 6, type: !32)
!37 = !DILocation(line: 0, scope: !29)
!38 = !DILocation(line: 7, column: 24, scope: !29, atomGroup: 12, atomRank: 2)
!39 = !DILocation(line: 7, column: 5, scope: !29, atomGroup: 13, atomRank: 1)
!40 = !DILocation(line: 7, column: 5, scope: !29, atomGroup: 14, atomRank: 1)
!41 = !DILocation(line: 8, column: 15, scope: !42, atomGroup: 5, atomRank: 2)
!42 = distinct !DILexicalBlock(scope: !29, file: !2, line: 7, column: 30)
!43 = !DILocation(line: 9, column: 15, scope: !42, atomGroup: 6, atomRank: 2)
!44 = !DILocation(line: 7, column: 5, scope: !29, atomGroup: 3, atomRank: 1)
!45 = !DILocation(line: 7, column: 5, scope: !29, atomGroup: 4, atomRank: 1)
!46 = distinct !{!46, !47, !48, !49}
!47 = !DILocation(line: 7, column: 5, scope: !29)
!48 = !DILocation(line: 10, column: 5, scope: !29)
!49 = !{!"llvm.loop.mustprogress"}
!50 = !DILocation(line: 11, column: 5, scope: !29, atomGroup: 8, atomRank: 1)
!51 = distinct !DISubprogram(name: "sum_to", scope: !2, file: !2, line: 14, type: !52, scopeLine: 14, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !12, retainedNodes: !54, keyInstructions: true)
!52 = !DISubroutineType(types: !53)
!53 = !{!15, !15}
!54 = !{!55, !56, !57}
!55 = !DILocalVariable(name: "limit", arg: 1, scope: !51, file: !2, line: 14, type: !15)
!56 = !DILocalVariable(name: "total", scope: !51, file: !2, line: 15, type: !15)
!57 = !DILocalVariable(name: "i", scope: !58, file: !2, line: 16, type: !15)
!58 = distinct !DILexicalBlock(scope: !51, file: !2, line: 16, column: 5)
!59 = !DILocation(line: 0, scope: !51)
!60 = !DILocation(line: 0, scope: !58)
!61 = !DILocation(line: 16, column: 23, scope: !62, atomGroup: 15, atomRank: 1)
!62 = distinct !DILexicalBlock(scope: !58, file: !2, line: 16, column: 5)
!63 = !DILocation(line: 16, column: 5, scope: !58, atomGroup: 16, atomRank: 1)
!64 = !DILocation(line: 16, column: 5, scope: !58)
!65 = !DILocation(line: 20, column: 5, scope: !51, atomGroup: 9, atomRank: 1)
!66 = distinct !DISubprogram(name: "is_same", scope: !2, file: !2, line: 23, type: !52, scopeLine: 23, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !12, retainedNodes: !67, keyInstructions: true)
!67 = !{!68}
!68 = !DILocalVariable(name: "value", arg: 1, scope: !66, file: !2, line: 23, type: !15)
!69 = !DILocation(line: 0, scope: !66)
!70 = !DILocation(line: 24, column: 5, scope: !66, atomGroup: 1, atomRank: 1)
!71 = distinct !DISubprogram(name: "small_constant", scope: !2, file: !2, line: 27, type: !72, scopeLine: 27, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !12, retainedNodes: !75, keyInstructions: true)
!72 = !DISubroutineType(types: !73)
!73 = !{!74}
!74 = !DIBasicType(name: "unsigned char", size: 8, encoding: DW_ATE_unsigned_char)
!75 = !{!76}
!76 = !DILocalVariable(name: "byte", scope: !71, file: !2, line: 28, type: !74)
!77 = !DILocation(line: 0, scope: !71)
!78 = !DILocation(line: 29, column: 5, scope: !71, atomGroup: 3, atomRank: 1)
!79 = distinct !DISubprogram(name: "wide_shift", scope: !2, file: !2, line: 32, type: !80, scopeLine: 32, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !12, retainedNodes: !83, keyInstructions: true)
!80 = !DISubroutineType(types: !81)
!81 = !{!82, !15}
!82 = !DIBasicType(name: "long", size: 64, encoding: DW_ATE_signed)
!83 = !{!84}
!84 = !DILocalVariable(name: "value", arg: 1, scope: !79, file: !2, line: 32, type: !15)
!85 = !DILocation(line: 0, scope: !79)
!86 = !DILocation(line: 33, column: 5, scope: !79, atomGroup: 1, atomRank: 1)
!87 = distinct !DISubprogram(name: "first_positive", scope: !2, file: !2, line: 36, type: !88, scopeLine: 36, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !12, retainedNodes: !92, keyInstructions: true)
!88 = !DISubroutineType(types: !89)
!89 = !{!15, !90, !15}
!90 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !91, size: 64)
!91 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !15)
!92 = !{!93, !94, !95, !96}
!93 = !DILocalVariable(name: "values", arg: 1, scope: !87, file: !2, line: 36, type: !90)
!94 = !DILocalVariable(name: "count", arg: 2, scope: !87, file: !2, line: 36, type: !15)
!95 = !DILocalVariable(name: "found", scope: !87, file: !2, line: 37, type: !15)
!96 = !DILocalVariable(name: "i", scope: !97, file: !2, line: 38, type: !15)
!97 = distinct !DILexicalBlock(scope: !87, file: !2, line: 38, column: 5)
!98 = !DILocation(line: 0, scope: !87)
!99 = !DILocation(line: 0, scope: !97)
!100 = !DILocation(line: 38, column: 23, scope: !101, atomGroup: 17, atomRank: 1)
!101 = distinct !DILexicalBlock(scope: !97, file: !2, line: 38, column: 5)
!102 = !DILocation(line: 38, column: 5, scope: !97, atomGroup: 18, atomRank: 1)
!103 = !DILocation(line: 38, column: 23, scope: !101, atomGroup: 2, atomRank: 1)
!104 = !DILocation(line: 38, column: 5, scope: !97)
!105 = !DILocation(line: 38, column: 33, scope: !101, atomGroup: 7, atomRank: 2)
!106 = !DILocation(line: 38, column: 5, scope: !97, atomGroup: 3, atomRank: 1)
!107 = distinct !{!107, !104, !108, !49}
!108 = !DILocation(line: 42, column: 5, scope: !97)
!109 = !DILocation(line: 39, column: 21, scope: !110)
!110 = distinct !DILexicalBlock(scope: !111, file: !2, line: 39, column: 13)
!111 = distinct !DILexicalBlock(scope: !101, file: !2, line: 38, column: 37)
!112 = !DILocation(line: 39, column: 31, scope: !110, atomGroup: 5, atomRank: 2)
!113 = !DILocation(line: 39, column: 19, scope: !110, atomGroup: 5, atomRank: 1)
!114 = !DILocation(line: 44, column: 1, scope: !87, atomGroup: 10, atomRank: 1)
!115 = distinct !DISubprogram(name: "skip_empty", scope: !2, file: !2, line: 46, type: !52, scopeLine: 46, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !12, retainedNodes: !116, keyInstructions: true)
!116 = !{!117}
!117 = !DILocalVariable(name: "value", arg: 1, scope: !115, file: !2, line: 46, type: !15)
!118 = !DILocation(line: 0, scope: !115)
!119 = !DILocation(line: 48, column: 5, scope: !115, atomGroup: 2, atomRank: 1)
!120 = distinct !DISubprogram(name: "truncated_half", scope: !2, file: !2, line: 51, type: !121, scopeLine: 51, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !12, retainedNodes: !122, keyInstructions: true)
!121 = !DISubroutineType(types: !14)
!122 = !{!123}
!123 = !DILocalVariable(name: "half", scope: !120, file: !2, line: 52, type: !15)
!124 = !DILocation(line: 0, scope: !120)
!125 = !DILocation(line: 53, column: 5, scope: !120, atomGroup: 3, atomRank: 1)
!126 = distinct !DISubprogram(name: "last_of_four", scope: !2, file: !2, line: 56, type: !121, scopeLine: 56, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !12, retainedNodes: !127, keyInstructions: true)
!127 = !{!128}
!128 = !DILocalVariable(name: "four", scope: !126, file: !2, line: 57, type: !129)
!129 = !DICompositeType(tag: DW_TAG_array_type, baseType: !15, size: 128, elements: !130)
!130 = !{!131}
!131 = !DISubrange(count: 4)
!132 = distinct !DIAssignID()
!133 = !DILocation(line: 0, scope: !126)
!134 = distinct !DIAssignID()
!135 = !DILocation(line: 58, column: 5, scope: !126, atomGroup: 3, atomRank: 1)
!136 = distinct !DISubprogram(name: "not_equal", scope: !2, file: !2, line: 61, type: !137, scopeLine: 61, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !12, retainedNodes: !139, keyInstructions: true)
!137 = !DISubroutineType(types: !138)
!138 = !{!15, !15, !15}
!139 = !{!140, !141}
!140 = !DILocalVariable(name: "a", arg: 1, scope: !136, file: !2, line: 61, type: !15)
!141 = !DILocalVariable(name: "b", arg: 2, scope: !136, file: !2, line: 61, type: !15)
!142 = !DILocation(line: 0, scope: !136)
!143 = !DILocation(line: 62, column: 9, scope: !144)
!144 = distinct !DILexicalBlock(scope: !136, file: !2, line: 62, column: 9)
!145 = !DILocation(line: 62, column: 12, scope: !144, atomGroup: 1, atomRank: 2)
!146 = !DILocation(line: 66, column: 1, scope: !136, atomGroup: 4, atomRank: 1)
!147 = distinct !DISubprogram(name: "array_size", scope: !2, file: !2, line: 68, type: !148, scopeLine: 68, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !12, retainedNodes: !151, keyInstructions: true)
!148 = !DISubroutineType(types: !149)
!149 = !{!15, !150}
!150 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !15, size: 64)
!151 = !{!152}
!152 = !DILocalVariable(name: "values", arg: 1, scope: !147, file: !2, line: 68, type: !150)
!153 = !DILocation(line: 0, scope: !147)
!154 = !DILocation(line: 69, column: 5, scope: !147, atomGroup: 1, atomRank: 1)
!155 = distinct !DISubprogram(name: "print_total", scope: !2, file: !2, line: 72, type: !156, scopeLine: 72, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !12, retainedNodes: !159, keyInstructions: true)
!156 = !DISubroutineType(types: !157)
!157 = !{null, !82, !158}
!158 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!159 = !{!160, !161}
!160 = !DILocalVariable(name: "total", arg: 1, scope: !155, file: !2, line: 72, type: !82)
!161 = !DILocalVariable(name: "mean", arg: 2, scope: !155, file: !2, line: 72, type: !158)
!162 = !DILocation(line: 0, scope: !155)
!163 = !DILocation(line: 73, column: 5, scope: !155)
!164 = !DILocation(line: 74, column: 5, scope: !155)
!165 = !DILocation(line: 75, column: 1, scope: !155, atomGroup: 1, atomRank: 1)
!166 = !DISubprogram(name: "printf", scope: !167, file: !167, line: 363, type: !168, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!167 = !DIFile(filename: "/usr/include/stdio.h", directory: "", checksumkind: CSK_MD5, checksum: "1e435c46987a169d9f9186f63a512303")
!168 = !DISubroutineType(types: !169)
!169 = !{!15, !170, null}
!170 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !171)
!171 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !172, size: 64)
!172 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !4)
!173 = distinct !DISubprogram(name: "scaled_sum", scope: !2, file: !2, line: 77, type: !88, scopeLine: 77, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !12, retainedNodes: !174, keyInstructions: true)
!174 = !{!175, !176, !177, !178}
!175 = !DILocalVariable(name: "values", arg: 1, scope: !173, file: !2, line: 77, type: !90)
!176 = !DILocalVariable(name: "count", arg: 2, scope: !173, file: !2, line: 77, type: !15)
!177 = !DILocalVariable(name: "total", scope: !173, file: !2, line: 78, type: !15)
!178 = !DILocalVariable(name: "i", scope: !179, file: !2, line: 79, type: !15)
!179 = distinct !DILexicalBlock(scope: !173, file: !2, line: 79, column: 5)
!180 = !DILocation(line: 0, scope: !173)
!181 = !DILocation(line: 0, scope: !179)
!182 = !DILocation(line: 79, column: 23, scope: !183, atomGroup: 19, atomRank: 1)
!183 = distinct !DILexicalBlock(scope: !179, file: !2, line: 79, column: 5)
!184 = !DILocation(line: 79, column: 5, scope: !179, atomGroup: 20, atomRank: 1)
!185 = !DILocation(line: 79, column: 23, scope: !183, atomGroup: 3, atomRank: 1)
!186 = !DILocation(line: 79, column: 5, scope: !179)
!187 = !DILocation(line: 79, column: 33, scope: !183, atomGroup: 7, atomRank: 2)
!188 = !DILocation(line: 80, column: 29, scope: !189)
!189 = distinct !DILexicalBlock(scope: !190, file: !2, line: 80, column: 13)
!190 = distinct !DILexicalBlock(scope: !183, file: !2, line: 79, column: 37)
!191 = !DILocation(line: 80, column: 39, scope: !189)
!192 = !DILocation(line: 80, column: 27, scope: !189, atomGroup: 5, atomRank: 2)
!193 = !DILocation(line: 79, column: 5, scope: !179, atomGroup: 4, atomRank: 1)
!194 = distinct !{!194, !49, !195, !196}
!195 = !{!"llvm.loop.isvectorized", i32 1}
!196 = !{!"llvm.loop.unroll.runtime.disable"}
!197 = !DILocation(line: 84, column: 5, scope: !173, atomGroup: 10, atomRank: 1)
!198 = distinct !{!198, !49, !196, !195}
!199 = distinct !DISubprogram(name: "clamp", scope: !2, file: !2, line: 87, type: !52, scopeLine: 87, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !12, retainedNodes: !200, keyInstructions: true)
!200 = !{!201, !202, !203}
!201 = !DILocalVariable(name: "value", arg: 1, scope: !199, file: !2, line: 87, type: !15)
!202 = !DILocalVariable(name: "low", scope: !199, file: !2, line: 88, type: !4)
!203 = !DILocalVariable(name: "high", scope: !199, file: !2, line: 89, type: !4)
!204 = !DILocation(line: 0, scope: !199)
!205 = !DILocation(line: 90, column: 15, scope: !206, atomGroup: 3, atomRank: 2)
!206 = distinct !DILexicalBlock(scope: !199, file: !2, line: 90, column: 9)
!207 = !DILocation(line: 90, column: 15, scope: !206, atomGroup: 3, atomRank: 1)
!208 = !DILocation(line: 97, column: 1, scope: !199, atomGroup: 8, atomRank: 1)
!209 = distinct !DISubprogram(name: "max_of", scope: !2, file: !2, line: 99, type: !88, scopeLine: 99, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !12, retainedNodes: !210, keyInstructions: true)
!210 = !{!211, !212, !213, !214}
!211 = !DILocalVariable(name: "values", arg: 1, scope: !209, file: !2, line: 99, type: !90)
!212 = !DILocalVariable(name: "count", arg: 2, scope: !209, file: !2, line: 99, type: !15)
!213 = !DILocalVariable(name: "best", scope: !209, file: !2, line: 100, type: !15)
!214 = !DILocalVariable(name: "i", scope: !215, file: !2, line: 101, type: !15)
!215 = distinct !DILexicalBlock(scope: !209, file: !2, line: 101, column: 5)
!216 = !DILocation(line: 0, scope: !209)
!217 = !DILocation(line: 100, column: 16, scope: !209, atomGroup: 1, atomRank: 2)
!218 = !DILocation(line: 0, scope: !215)
!219 = !DILocation(line: 101, column: 23, scope: !220, atomGroup: 21, atomRank: 1)
!220 = distinct !DILexicalBlock(scope: !215, file: !2, line: 101, column: 5)
!221 = !DILocation(line: 101, column: 5, scope: !215, atomGroup: 22, atomRank: 1)
!222 = !DILocation(line: 101, column: 23, scope: !220, atomGroup: 3, atomRank: 1)
!223 = !DILocation(line: 101, column: 5, scope: !215)
!224 = !DILocation(line: 102, column: 20, scope: !225)
!225 = distinct !DILexicalBlock(scope: !226, file: !2, line: 102, column: 13)
!226 = distinct !DILexicalBlock(scope: !220, file: !2, line: 101, column: 37)
!227 = !DILocation(line: 101, column: 5, scope: !215, atomGroup: 4, atomRank: 1)
!228 = distinct !{!228, !49, !195, !196}
!229 = !DILocation(line: 106, column: 5, scope: !209, atomGroup: 11, atomRank: 1)
!230 = !DILocation(line: 101, column: 33, scope: !220, atomGroup: 8, atomRank: 2)
!231 = distinct !{!231, !49, !196, !195}
!232 = distinct !DISubprogram(name: "bump", scope: !2, file: !2, line: 109, type: !52, scopeLine: 109, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !12, retainedNodes: !233, keyInstructions: true)
!233 = !{!234}
!234 = !DILocalVariable(name: "i", arg: 1, scope: !232, file: !2, line: 109, type: !15)
!235 = !DILocation(line: 0, scope: !232)
!236 = !DILocation(line: 110, column: 13, scope: !232, atomGroup: 1, atomRank: 2)
!237 = !DILocation(line: 111, column: 5, scope: !232, atomGroup: 3, atomRank: 1)
!238 = distinct !DISubprogram(name: "main", scope: !2, file: !2, line: 114, type: !121, scopeLine: 114, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !12, retainedNodes: !239, keyInstructions: true)
!239 = !{!240}
!240 = !DILocalVariable(name: "values", scope: !238, file: !2, line: 115, type: !241)
!241 = !DICompositeType(tag: DW_TAG_array_type, baseType: !15, size: 192, elements: !242)
!242 = !{!243}
!243 = !DISubrange(count: 6)
!244 = distinct !DIAssignID()
!245 = !DILocation(line: 0, scope: !238)
!246 = distinct !DIAssignID()
!247 = !DILocation(line: 0, scope: !155, inlinedAt: !248)
!248 = distinct !DILocation(line: 116, column: 5, scope: !238)
!249 = !DILocation(line: 73, column: 5, scope: !155, inlinedAt: !248)
!250 = !DILocation(line: 74, column: 5, scope: !155, inlinedAt: !248)
!251 = !DILocation(line: 117, column: 5, scope: !238, atomGroup: 3, atomRank: 1)
