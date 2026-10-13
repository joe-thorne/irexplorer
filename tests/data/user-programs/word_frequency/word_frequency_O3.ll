; ModuleID = '/workspace/user-programs/word_frequency.c'
source_filename = "/workspace/user-programs/word_frequency.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%struct.table = type { [256 x %struct.entry], i32 }
%struct.entry = type { [24 x i8], i32, i32 }

@main.table = internal global %struct.table zeroinitializer, align 4, !dbg !0
@main.entries = internal global [256 x %struct.entry] zeroinitializer, align 16, !dbg !37
@.str = private unnamed_addr constant [4 x i8] c"fox\00", align 1, !dbg !50
@.str.1 = private unnamed_addr constant [4 x i8] c"cat\00", align 1, !dbg !55
@.str.2 = private unnamed_addr constant [18 x i8] c"fox: %d, cat: %d\0A\00", align 1, !dbg !57
@stderr = external local_unnamed_addr global ptr, align 8
@.str.3 = private unnamed_addr constant [23 x i8] c"table full at word %d\0A\00", align 1, !dbg !62
@.str.4 = private unnamed_addr constant [285 x i8] c"The quick brown fox jumps over the lazy dog. The dog sleeps, and the fox runs into the forest. In the forest the fox finds a river; the river is cold and the fox is quick. A lazy dog never finds the river, but the quick fox always does. Over the hills and over the river the fox runs.\00", align 1, !dbg !67
@.str.5 = private unnamed_addr constant [23 x i8] c"%d words, %d distinct\0A\00", align 1, !dbg !76
@.str.6 = private unnamed_addr constant [11 x i8] c"%-10s %3d \00", align 1, !dbg !78
@.str.7 = private unnamed_addr constant [18 x i8] c"longest word: %s\0A\00", align 1, !dbg !83
@.str.8 = private unnamed_addr constant [27 x i8] c"mean length: %.2f letters\0A\00", align 1, !dbg !85
@.str.9 = private unnamed_addr constant [21 x i8] c"words seen once: %d\0A\00", align 1, !dbg !90
@stdout = external local_unnamed_addr global ptr, align 8

; Function Attrs: nofree nounwind uwtable
define dso_local range(i32 0, 2) i32 @main() local_unnamed_addr #0 !dbg !2 {
entry:
  %word.i = alloca [24 x i8], align 16, !DIAssignID !116
    #dbg_value(ptr @main.table, !117, !DIExpression(), !123)
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(8196) @main.table, i8 0, i64 8196, i1 false), !dbg !125
    #dbg_assign(i1 poison, !126, !DIExpression(), !116, ptr %word.i, !DIExpression(), !134)
    #dbg_value(ptr @main.table, !131, !DIExpression(), !134)
    #dbg_value(ptr @.str.4, !132, !DIExpression(), !134)
  call void @llvm.lifetime.start.p0(ptr nonnull %word.i) #11, !dbg !136
    #dbg_value(i32 0, !133, !DIExpression(), !134)
  %.pre48.i.i = tail call ptr @__ctype_b_loc() #12, !dbg !134
  br label %while.cond.i, !dbg !137

while.cond.i:                                     ; preds = %if.end.i, %entry
  %inc.i1221.i = phi i32 [ 0, %entry ], [ %inc.i1220.i, %if.end.i ]
  %text.addr.0.i = phi ptr [ @.str.4, %entry ], [ %incdec.ptr22.i.i, %if.end.i ]
  %position.0.i = phi i32 [ 0, %entry ], [ %inc.i, %if.end.i ], !dbg !134
    #dbg_value(ptr %text.addr.0.i, !132, !DIExpression(), !134)
    #dbg_value(i32 %position.0.i, !133, !DIExpression(), !134)
    #dbg_value(ptr poison, !138, !DIExpression(), !153)
    #dbg_value(ptr %word.i, !145, !DIExpression(), !153)
    #dbg_value(ptr %text.addr.0.i, !146, !DIExpression(), !153)
  %0 = load i8, ptr %text.addr.0.i, align 1, !dbg !155, !tbaa !156
  %cmp.not37.i.i = icmp eq i8 %0, 0, !dbg !157
  %.pre.i = load ptr, ptr %.pre48.i.i, align 8, !dbg !158, !tbaa !159
  br i1 %cmp.not37.i.i, label %while.end.i.i, label %land.rhs.i.i, !dbg !162

land.rhs.i.i:                                     ; preds = %while.cond.i, %while.body.i.i
  %1 = phi i8 [ %4, %while.body.i.i ], [ %0, %while.cond.i ]
  %p.038.i.i = phi ptr [ %incdec.ptr.i.i, %while.body.i.i ], [ %text.addr.0.i, %while.cond.i ]
    #dbg_value(ptr %p.038.i.i, !146, !DIExpression(), !153)
  %idxprom.i.i = zext i8 %1 to i64, !dbg !163
  %arrayidx.i.i = getelementptr inbounds nuw i16, ptr %.pre.i, i64 %idxprom.i.i, !dbg !163
  %2 = load i16, ptr %arrayidx.i.i, align 2, !dbg !163, !tbaa !164
  %3 = and i16 %2, 1024, !dbg !163
  %tobool.not.i.i = icmp eq i16 %3, 0, !dbg !166
  br i1 %tobool.not.i.i, label %while.body.i.i, label %while.end.i.i, !dbg !167

while.body.i.i:                                   ; preds = %land.rhs.i.i
  %incdec.ptr.i.i = getelementptr inbounds nuw i8, ptr %p.038.i.i, i64 1, !dbg !168
    #dbg_value(ptr %incdec.ptr.i.i, !146, !DIExpression(), !153)
  %4 = load i8, ptr %incdec.ptr.i.i, align 1, !dbg !155, !tbaa !156
  %cmp.not.i.i = icmp eq i8 %4, 0, !dbg !170
  br i1 %cmp.not.i.i, label %while.body.i.while.end.loopexit.i_crit_edge.i, label %land.rhs.i.i, !dbg !171, !llvm.loop !172

while.body.i.while.end.loopexit.i_crit_edge.i:    ; preds = %while.body.i.i
  br label %while.end.i.i, !dbg !171, !llvm.loop !176

while.end.i.i:                                    ; preds = %land.rhs.i.i, %while.body.i.while.end.loopexit.i_crit_edge.i, %while.cond.i
  %idxprom740.i.i = phi i64 [ 0, %while.cond.i ], [ 0, %while.body.i.while.end.loopexit.i_crit_edge.i ], [ %idxprom.i.i, %land.rhs.i.i ], !dbg !177
  %p.0.lcssa.i.i = phi ptr [ %text.addr.0.i, %while.cond.i ], [ %incdec.ptr.i.i, %while.body.i.while.end.loopexit.i_crit_edge.i ], [ %p.038.i.i, %land.rhs.i.i ], !dbg !153
    #dbg_value(ptr %p.0.lcssa.i.i, !146, !DIExpression(), !153)
    #dbg_value(i32 0, !147, !DIExpression(), !153)
  %arrayidx841.i.i = getelementptr inbounds nuw i16, ptr %.pre.i, i64 %idxprom740.i.i, !dbg !158
  %5 = load i16, ptr %arrayidx841.i.i, align 2, !dbg !158, !tbaa !164
  %6 = and i16 %5, 1024, !dbg !158
  %tobool11.not42.i.i = icmp eq i16 %6, 0, !dbg !178
  br i1 %tobool11.not42.i.i, label %count_words.exit, label %while.body12.i.i, !dbg !179

while.body12.i.i:                                 ; preds = %while.end.i.i, %if.end.i.i
  %idxprom745.i.i = phi i64 [ %idxprom7.i.i, %if.end.i.i ], [ %idxprom740.i.i, %while.end.i.i ]
  %p.144.i.i = phi ptr [ %incdec.ptr22.i.i, %if.end.i.i ], [ %p.0.lcssa.i.i, %while.end.i.i ]
  %length.043.i.i = phi i32 [ %length.1.i.i, %if.end.i.i ], [ 0, %while.end.i.i ]
    #dbg_value(ptr %p.144.i.i, !146, !DIExpression(), !153)
    #dbg_value(i32 %length.043.i.i, !147, !DIExpression(), !153)
  %cmp13.i.i = icmp slt i32 %length.043.i.i, 23, !dbg !180
  br i1 %cmp13.i.i, label %if.then.i.i, label %if.end.i.i, !dbg !181

if.then.i.i:                                      ; preds = %while.body12.i.i
  %call15.i.i = tail call ptr @__ctype_tolower_loc() #12, !dbg !182
  %7 = load ptr, ptr %call15.i.i, align 8, !dbg !182, !tbaa !184
  %arrayidx18.i.i = getelementptr inbounds nuw i32, ptr %7, i64 %idxprom745.i.i, !dbg !182
  %8 = load i32, ptr %arrayidx18.i.i, align 4, !dbg !186, !tbaa !112
    #dbg_value(i32 %8, !148, !DIExpression(), !187)
  %conv19.i.i = trunc i32 %8 to i8, !dbg !188
  %inc.i.i = add nsw i32 %length.043.i.i, 1, !dbg !189
    #dbg_value(i32 %inc.i.i, !147, !DIExpression(), !153)
  %idxprom20.i.i = sext i32 %length.043.i.i to i64, !dbg !190
  %arrayidx21.i.i = getelementptr inbounds i8, ptr %word.i, i64 %idxprom20.i.i, !dbg !190
  store i8 %conv19.i.i, ptr %arrayidx21.i.i, align 1, !dbg !191, !tbaa !156
  br label %if.end.i.i, !dbg !192

if.end.i.i:                                       ; preds = %if.then.i.i, %while.body12.i.i
  %length.1.i.i = phi i32 [ %inc.i.i, %if.then.i.i ], [ %length.043.i.i, %while.body12.i.i ], !dbg !153
    #dbg_value(i32 %length.1.i.i, !147, !DIExpression(), !153)
  %incdec.ptr22.i.i = getelementptr inbounds nuw i8, ptr %p.144.i.i, i64 1, !dbg !193
    #dbg_value(ptr %incdec.ptr22.i.i, !146, !DIExpression(), !153)
  %9 = load i8, ptr %incdec.ptr22.i.i, align 1, !dbg !177, !tbaa !156
  %idxprom7.i.i = zext i8 %9 to i64, !dbg !158
  %arrayidx8.i.i = getelementptr inbounds nuw i16, ptr %.pre.i, i64 %idxprom7.i.i, !dbg !158
  %10 = load i16, ptr %arrayidx8.i.i, align 2, !dbg !158, !tbaa !164
  %11 = and i16 %10, 1024, !dbg !158
  %tobool11.not.i.i = icmp eq i16 %11, 0, !dbg !194
  br i1 %tobool11.not.i.i, label %next_word.exit.i, label %while.body12.i.i, !dbg !195, !llvm.loop !196

next_word.exit.i:                                 ; preds = %if.end.i.i
  %idxprom24.i.i = sext i32 %length.1.i.i to i64, !dbg !199
  %arrayidx25.i.i = getelementptr inbounds i8, ptr %word.i, i64 %idxprom24.i.i, !dbg !199
  store i8 0, ptr %arrayidx25.i.i, align 1, !dbg !200, !tbaa !156
    #dbg_value(ptr %incdec.ptr22.i.i, !132, !DIExpression(), !134)
  %cmp.i = icmp sgt i32 %length.1.i.i, 0, !dbg !201
  br i1 %cmp.i, label %while.body.i, label %count_words.exit, !dbg !202

while.body.i:                                     ; preds = %next_word.exit.i
    #dbg_value(ptr @main.table, !203, !DIExpression(), !217)
    #dbg_value(ptr %word.i, !208, !DIExpression(), !217)
    #dbg_value(i32 %position.0.i, !209, !DIExpression(), !217)
    #dbg_value(ptr %word.i, !221, !DIExpression(), !229)
    #dbg_value(i32 -2128831035, !226, !DIExpression(), !229)
    #dbg_value(ptr %word.i, !227, !DIExpression(), !231)
  %12 = load i8, ptr %word.i, align 16, !dbg !232, !tbaa !156
  %cmp.not7.i.i.i = icmp eq i8 %12, 0, !dbg !234
  br i1 %cmp.not7.i.i.i, label %for.body.i.i.preheader, label %for.body.i.i.i, !dbg !235

for.body.i.i.i:                                   ; preds = %while.body.i, %for.body.i.i.i
  %13 = phi i8 [ %14, %for.body.i.i.i ], [ %12, %while.body.i ]
  %p.09.i.i.i = phi ptr [ %incdec.ptr.i.i.i, %for.body.i.i.i ], [ %word.i, %while.body.i ]
  %hash.08.i.i.i = phi i32 [ %mul.i.i.i, %for.body.i.i.i ], [ -2128831035, %while.body.i ]
    #dbg_value(ptr %p.09.i.i.i, !227, !DIExpression(), !231)
    #dbg_value(i32 %hash.08.i.i.i, !226, !DIExpression(), !229)
  %conv2.i.i.i = zext i8 %13 to i32, !dbg !236
  %xor.i.i.i = xor i32 %hash.08.i.i.i, %conv2.i.i.i, !dbg !238
    #dbg_value(i32 %xor.i.i.i, !226, !DIExpression(), !229)
  %mul.i.i.i = mul i32 %xor.i.i.i, 16777619, !dbg !239
    #dbg_value(i32 %mul.i.i.i, !226, !DIExpression(), !229)
  %incdec.ptr.i.i.i = getelementptr inbounds nuw i8, ptr %p.09.i.i.i, i64 1, !dbg !240
    #dbg_value(ptr %incdec.ptr.i.i.i, !227, !DIExpression(), !231)
  %14 = load i8, ptr %incdec.ptr.i.i.i, align 1, !dbg !232, !tbaa !156
  %cmp.not.i.i.i = icmp eq i8 %14, 0, !dbg !241
  br i1 %cmp.not.i.i.i, label %for.body.i.i.preheader, label %for.body.i.i.i, !dbg !242, !llvm.loop !243

for.body.i.i.preheader:                           ; preds = %for.body.i.i.i, %while.body.i
  %index.012.in.i.i.ph = phi i32 [ -2128831035, %while.body.i ], [ %mul.i.i.i, %for.body.i.i.i ]
  br label %for.body.i.i, !dbg !246

for.body.i.i:                                     ; preds = %for.body.i.i.preheader, %for.inc.i.i
  %index.012.in.i.i = phi i32 [ %add.i.i, %for.inc.i.i ], [ %index.012.in.i.i.ph, %for.body.i.i.preheader ]
  %probe.011.i.i = phi i32 [ %inc14.i.i, %for.inc.i.i ], [ 0, %for.body.i.i.preheader ]
  %index.012.i.i = and i32 %index.012.in.i.i, 255, !dbg !217
    #dbg_value(i32 %probe.011.i.i, !211, !DIExpression(), !247)
  %idxprom.i8.i = zext nneg i32 %index.012.i.i to i64, !dbg !248
  %arrayidx.i9.i = getelementptr inbounds nuw %struct.entry, ptr @main.table, i64 %idxprom.i8.i, !dbg !249
    #dbg_value(ptr %arrayidx.i9.i, !213, !DIExpression(), !250)
  %count.i.i = getelementptr inbounds nuw i8, ptr %arrayidx.i9.i, i64 24, !dbg !251
  %15 = load i32, ptr %count.i.i, align 4, !dbg !251, !tbaa !253
  %cmp1.i.i = icmp eq i32 %15, 0, !dbg !255
  br i1 %cmp1.i.i, label %if.then.i11.i, label %if.end.i10.i, !dbg !256

if.then.i11.i:                                    ; preds = %for.body.i.i
  %count.i.i.le101 = getelementptr inbounds nuw i8, ptr %arrayidx.i9.i, i64 24
  %call3.i.i = call ptr @strncpy(ptr noundef nonnull dereferenceable(1) %arrayidx.i9.i, ptr noundef nonnull readonly dereferenceable(1) %word.i, i64 noundef 23) #11, !dbg !257
  store i32 1, ptr %count.i.i.le101, align 4, !dbg !259, !tbaa !253
  %first_seen.i.i = getelementptr inbounds nuw i8, ptr %arrayidx.i9.i, i64 28, !dbg !260
  store i32 %position.0.i, ptr %first_seen.i.i, align 4, !dbg !261, !tbaa !262
  %inc.i12.i = add nsw i32 %inc.i1221.i, 1, !dbg !263
  store i32 %inc.i12.i, ptr getelementptr inbounds nuw (i8, ptr @main.table, i64 8192), align 4, !dbg !264, !tbaa !265
  br label %if.end.i, !dbg !267

if.end.i10.i:                                     ; preds = %for.body.i.i
  %call7.i.i = call i32 @strcmp(ptr noundef nonnull dereferenceable(1) %arrayidx.i9.i, ptr noundef nonnull readonly dereferenceable(1) %word.i) #13, !dbg !268
  %cmp8.i.i = icmp eq i32 %call7.i.i, 0, !dbg !270
  br i1 %cmp8.i.i, label %if.then9.i.i, label %for.inc.i.i, !dbg !271

if.then9.i.i:                                     ; preds = %if.end.i10.i
  %count.i.i.le = getelementptr inbounds nuw i8, ptr %arrayidx.i9.i, i64 24
  %inc11.i.i = add nsw i32 %15, 1, !dbg !272
  store i32 %inc11.i.i, ptr %count.i.i.le, align 4, !dbg !274, !tbaa !253
  br label %if.end.i, !dbg !275

for.inc.i.i:                                      ; preds = %if.end.i10.i
  %add.i.i = add nuw nsw i32 %index.012.i.i, 1, !dbg !276
    #dbg_value(i32 %add.i.i, !210, !DIExpression(DW_OP_constu, 255, DW_OP_and, DW_OP_stack_value), !217)
  %inc14.i.i = add nuw nsw i32 %probe.011.i.i, 1, !dbg !277
    #dbg_value(i32 %inc14.i.i, !211, !DIExpression(), !247)
  %exitcond.i.i = icmp eq i32 %inc14.i.i, 256, !dbg !278
  br i1 %exitcond.i.i, label %if.then.i, label %for.body.i.i, !dbg !279, !llvm.loop !280

if.then.i:                                        ; preds = %for.inc.i.i
  %16 = load ptr, ptr @stderr, align 8, !dbg !282, !tbaa !284
  %call4.i = tail call i32 (ptr, ptr, ...) @fprintf(ptr noundef %16, ptr noundef nonnull @.str.3, i32 noundef %position.0.i) #14, !dbg !286
  br label %count_words.exit, !dbg !287

if.end.i:                                         ; preds = %if.then9.i.i, %if.then.i11.i
  %inc.i1220.i = phi i32 [ %inc.i12.i, %if.then.i11.i ], [ %inc.i1221.i, %if.then9.i.i ]
  %inc.i = add nuw nsw i32 %position.0.i, 1, !dbg !288
    #dbg_value(i32 %inc.i, !133, !DIExpression(), !134)
  br label %while.cond.i, !dbg !137, !llvm.loop !289

count_words.exit:                                 ; preds = %while.end.i.i, %next_word.exit.i, %if.then.i
  call void @llvm.lifetime.end.p0(ptr nonnull %word.i) #11, !dbg !291
    #dbg_value(i32 %position.0.i, !96, !DIExpression(), !292)
    #dbg_value(ptr @main.table, !293, !DIExpression(), !304)
    #dbg_value(ptr @main.entries, !300, !DIExpression(), !304)
    #dbg_value(i32 0, !301, !DIExpression(), !304)
    #dbg_value(i32 0, !302, !DIExpression(), !306)
  br label %for.body.i, !dbg !307

for.body.i:                                       ; preds = %for.inc.i.1, %count_words.exit
  %indvars.iv.i = phi i64 [ 0, %count_words.exit ], [ %indvars.iv.next.i.1, %for.inc.i.1 ]
  %n.01.i = phi i32 [ 0, %count_words.exit ], [ %n.1.i.1, %for.inc.i.1 ]
    #dbg_value(i64 %indvars.iv.i, !302, !DIExpression(), !306)
    #dbg_value(i32 %n.01.i, !301, !DIExpression(), !304)
  %arrayidx.i = getelementptr inbounds nuw %struct.entry, ptr @main.table, i64 %indvars.iv.i, !dbg !308
  %count.i = getelementptr inbounds nuw i8, ptr %arrayidx.i, i64 24, !dbg !312
  %17 = load i32, ptr %count.i, align 4, !dbg !312, !tbaa !253
  %cmp1.i = icmp sgt i32 %17, 0, !dbg !313
  br i1 %cmp1.i, label %if.then.i8, label %for.inc.i, !dbg !314

if.then.i8:                                       ; preds = %for.body.i
  %inc.i9 = add nsw i32 %n.01.i, 1, !dbg !315
    #dbg_value(i32 %inc.i9, !301, !DIExpression(), !304)
  %idxprom2.i = sext i32 %n.01.i to i64, !dbg !317
  %arrayidx3.i = getelementptr inbounds %struct.entry, ptr @main.entries, i64 %idxprom2.i, !dbg !317
  tail call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %arrayidx3.i, ptr noundef nonnull align 4 dereferenceable(32) %arrayidx.i, i64 32, i1 false), !dbg !318, !tbaa.struct !319
  br label %for.inc.i, !dbg !320

for.inc.i:                                        ; preds = %if.then.i8, %for.body.i
  %n.1.i = phi i32 [ %inc.i9, %if.then.i8 ], [ %n.01.i, %for.body.i ], !dbg !304
    #dbg_value(i32 %n.1.i, !301, !DIExpression(), !304)
    #dbg_value(i64 %indvars.iv.i, !302, !DIExpression(DW_OP_constu, 1, DW_OP_or, DW_OP_stack_value), !306)
  %18 = getelementptr inbounds nuw %struct.entry, ptr @main.table, i64 %indvars.iv.i, !dbg !308
  %count.i.1 = getelementptr inbounds nuw i8, ptr %18, i64 56, !dbg !312
  %19 = load i32, ptr %count.i.1, align 4, !dbg !312, !tbaa !253
  %cmp1.i.1 = icmp sgt i32 %19, 0, !dbg !321
  br i1 %cmp1.i.1, label %if.then.i8.1, label %for.inc.i.1, !dbg !322

if.then.i8.1:                                     ; preds = %for.inc.i
  %arrayidx.i.1 = getelementptr inbounds nuw i8, ptr %18, i64 32, !dbg !308
  %inc.i9.1 = add nsw i32 %n.1.i, 1, !dbg !323
    #dbg_value(i32 %inc.i9.1, !301, !DIExpression(), !304)
  %idxprom2.i.1 = sext i32 %n.1.i to i64, !dbg !317
  %arrayidx3.i.1 = getelementptr inbounds %struct.entry, ptr @main.entries, i64 %idxprom2.i.1, !dbg !317
  tail call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %arrayidx3.i.1, ptr noundef nonnull align 4 dereferenceable(32) %arrayidx.i.1, i64 32, i1 false), !dbg !324, !tbaa.struct !319
  br label %for.inc.i.1, !dbg !320

for.inc.i.1:                                      ; preds = %if.then.i8.1, %for.inc.i
  %n.1.i.1 = phi i32 [ %inc.i9.1, %if.then.i8.1 ], [ %n.1.i, %for.inc.i ], !dbg !304
    #dbg_value(i32 %n.1.i.1, !301, !DIExpression(), !304)
  %indvars.iv.next.i.1 = add nuw nsw i64 %indvars.iv.i, 2, !dbg !325
    #dbg_value(i64 %indvars.iv.next.i.1, !302, !DIExpression(), !306)
  %exitcond.not.i.1 = icmp eq i64 %indvars.iv.next.i.1, 256, !dbg !326
  br i1 %exitcond.not.i.1, label %collect.exit, label %for.body.i, !dbg !327, !llvm.loop !328

collect.exit:                                     ; preds = %for.inc.i.1
  %conv.i = sext i32 %n.1.i.1 to i64, !dbg !331
  tail call void @qsort(ptr noundef nonnull @main.entries, i64 noundef %conv.i, i64 noundef 32, ptr noundef nonnull @by_count) #11, !dbg !332
    #dbg_value(i32 %n.1.i.1, !97, !DIExpression(), !292)
    #dbg_value(ptr @main.entries, !333, !DIExpression(), !346)
    #dbg_value(i32 %n.1.i.1, !340, !DIExpression(), !346)
    #dbg_value(i32 %position.0.i, !341, !DIExpression(), !346)
    #dbg_value(i32 poison, !342, !DIExpression(), !346)
  %call.i = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.5, i32 noundef %position.0.i, i32 noundef %n.1.i.1), !dbg !348
    #dbg_value(i32 0, !343, !DIExpression(), !349)
  %cmp14.i = icmp sgt i32 %n.1.i.1, 0, !dbg !350
  br i1 %cmp14.i, label %for.body.preheader.i, label %mean_length.exit.i, !dbg !352

for.body.preheader.i:                             ; preds = %collect.exit
  %20 = tail call i32 @llvm.umin.i32(i32 %n.1.i.1, i32 8), !dbg !353
    #dbg_value(i32 %20, !342, !DIExpression(), !346)
  %wide.trip.count.i = zext nneg i32 %20 to i64, !dbg !354
  br label %for.body.i10, !dbg !355

for.cond.cleanup.i:                               ; preds = %print_bar.exit.i
    #dbg_value(ptr @main.entries, !356, !DIExpression(), !369)
    #dbg_value(i32 %n.1.i.1, !361, !DIExpression(), !369)
    #dbg_value(ptr null, !362, !DIExpression(), !369)
    #dbg_value(i64 0, !363, !DIExpression(), !369)
    #dbg_value(i32 0, !364, !DIExpression(), !371)
  %wide.trip.count.i.i = zext nneg i32 %n.1.i.1 to i64, !dbg !372
  br label %for.body.i.i17, !dbg !373

for.body.i.i17:                                   ; preds = %for.body.i.i17, %for.cond.cleanup.i
  %indvars.iv.i.i = phi i64 [ 0, %for.cond.cleanup.i ], [ %indvars.iv.next.i.i, %for.body.i.i17 ]
  %best.05.i.i = phi ptr [ null, %for.cond.cleanup.i ], [ %spec.select9.i.i, %for.body.i.i17 ]
  %best_length.03.i.i = phi i64 [ 0, %for.cond.cleanup.i ], [ %spec.select.i.i, %for.body.i.i17 ]
    #dbg_value(ptr %best.05.i.i, !362, !DIExpression(), !369)
    #dbg_value(i64 %indvars.iv.i.i, !364, !DIExpression(), !371)
    #dbg_value(i64 %best_length.03.i.i, !363, !DIExpression(), !369)
  %arrayidx.i.i18 = getelementptr inbounds nuw %struct.entry, ptr @main.entries, i64 %indvars.iv.i.i, !dbg !374
  %call.i.i = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %arrayidx.i.i18) #13, !dbg !375
    #dbg_value(i64 %call.i.i, !366, !DIExpression(), !376)
  %cmp1.i.i19 = icmp ugt i64 %call.i.i, %best_length.03.i.i, !dbg !377
  %spec.select.i.i = tail call i64 @llvm.umax.i64(i64 %call.i.i, i64 %best_length.03.i.i), !dbg !379
  %spec.select9.i.i = select i1 %cmp1.i.i19, ptr %arrayidx.i.i18, ptr %best.05.i.i, !dbg !379
    #dbg_value(ptr %spec.select9.i.i, !362, !DIExpression(), !369)
    #dbg_value(i64 %spec.select.i.i, !363, !DIExpression(), !369)
  %indvars.iv.next.i.i = add nuw nsw i64 %indvars.iv.i.i, 1, !dbg !380
    #dbg_value(i64 %indvars.iv.next.i.i, !364, !DIExpression(), !371)
  %exitcond.not.i.i = icmp eq i64 %indvars.iv.next.i.i, %wide.trip.count.i.i, !dbg !372
  br i1 %exitcond.not.i.i, label %longest.exit.i, label %for.body.i.i17, !dbg !381, !llvm.loop !382

longest.exit.i:                                   ; preds = %for.body.i.i17
    #dbg_value(ptr %spec.select9.i.i, !345, !DIExpression(), !346)
  %cmp12.not.i = icmp eq ptr %spec.select9.i.i, null, !dbg !384
  br i1 %cmp12.not.i, label %for.body.i41.i.preheader, label %if.then.i20, !dbg !386

for.body.i41.i.preheader:                         ; preds = %if.then.i20, %longest.exit.i
  br label %for.body.i41.i, !dbg !387

for.body.i10:                                     ; preds = %print_bar.exit.i, %for.body.preheader.i
  %indvars.iv.i11 = phi i64 [ 0, %for.body.preheader.i ], [ %indvars.iv.next.i15, %print_bar.exit.i ]
    #dbg_value(i64 %indvars.iv.i11, !343, !DIExpression(), !349)
  %arrayidx.i12 = getelementptr inbounds nuw %struct.entry, ptr @main.entries, i64 %indvars.iv.i11, !dbg !399
  %count.i13 = getelementptr inbounds nuw i8, ptr %arrayidx.i12, i64 24, !dbg !401
  %21 = load i32, ptr %count.i13, align 8, !dbg !401, !tbaa !253
  %call4.i14 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.6, ptr noundef nonnull %arrayidx.i12, i32 noundef %21), !dbg !402
  %22 = load i32, ptr getelementptr inbounds nuw (i8, ptr @main.entries, i64 24), align 8, !dbg !403, !tbaa !253
    #dbg_value(i32 poison, !404, !DIExpression(), !413)
    #dbg_value(i32 %22, !409, !DIExpression(), !413)
  %cmp.i.i = icmp sgt i32 %22, 0, !dbg !415
  br i1 %cmp.i.i, label %cond.end.i.i, label %print_bar.exit.i, !dbg !416

cond.end.i.i:                                     ; preds = %for.body.i10
  %23 = load i32, ptr %count.i13, align 8, !dbg !417, !tbaa !253
    #dbg_value(i32 %23, !404, !DIExpression(), !413)
  %mul.i.i = mul nsw i32 %23, 30, !dbg !418
  %div.i.i = sdiv i32 %mul.i.i, %22, !dbg !419
    #dbg_value(i32 %div.i.i, !410, !DIExpression(), !413)
    #dbg_value(i32 0, !411, !DIExpression(), !420)
  %cmp16.i.i = icmp sgt i32 %div.i.i, 0, !dbg !421
  br i1 %cmp16.i.i, label %for.body.i36.i, label %print_bar.exit.i, !dbg !423

for.body.i36.i:                                   ; preds = %cond.end.i.i, %for.body.i36.i
  %i.07.i.i = phi i32 [ %inc.i.i25, %for.body.i36.i ], [ 0, %cond.end.i.i ]
    #dbg_value(i32 %i.07.i.i, !411, !DIExpression(), !420)
    #dbg_value(i32 35, !424, !DIExpression(), !430)
  %24 = load ptr, ptr @stdout, align 8, !dbg !433, !tbaa !284
  %call.i5.i.i = tail call i32 @putc(i32 noundef 35, ptr noundef %24), !dbg !434
  %inc.i.i25 = add nuw nsw i32 %i.07.i.i, 1, !dbg !435
    #dbg_value(i32 %inc.i.i25, !411, !DIExpression(), !420)
  %exitcond.not.i37.i = icmp eq i32 %inc.i.i25, %div.i.i, !dbg !436
  br i1 %exitcond.not.i37.i, label %print_bar.exit.i, label %for.body.i36.i, !dbg !437, !llvm.loop !438

print_bar.exit.i:                                 ; preds = %for.body.i36.i, %cond.end.i.i, %for.body.i10
    #dbg_value(i32 10, !424, !DIExpression(), !441)
  %25 = load ptr, ptr @stdout, align 8, !dbg !443, !tbaa !284
  %call.i.i.i = tail call i32 @putc(i32 noundef 10, ptr noundef %25), !dbg !444
  %indvars.iv.next.i15 = add nuw nsw i64 %indvars.iv.i11, 1, !dbg !445
    #dbg_value(i64 %indvars.iv.next.i15, !343, !DIExpression(), !349)
  %exitcond.not.i16 = icmp eq i64 %indvars.iv.next.i15, %wide.trip.count.i, !dbg !354
  br i1 %exitcond.not.i16, label %for.cond.cleanup.i, label %for.body.i10, !dbg !446, !llvm.loop !447

if.then.i20:                                      ; preds = %longest.exit.i
  %call15.i = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.7, ptr noundef nonnull %spec.select9.i.i), !dbg !449
  br label %for.body.i41.i.preheader, !dbg !451

for.cond.cleanup.i.i:                             ; preds = %for.body.i41.i
  %cmp8.i.i23 = icmp sgt i64 %add7.i.i, 0, !dbg !452
  %26 = sitofp i64 %add.i.i22 to double, !dbg !453
  %conv11.i.i = uitofp nneg i64 %add7.i.i to double, !dbg !453
  %div.i48.i = fdiv double %26, %conv11.i.i, !dbg !453
  %.ph.i = select i1 %cmp8.i.i23, double %div.i48.i, double 0.000000e+00, !dbg !453
  %call173.i = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.8, double noundef %.ph.i), !dbg !454
    #dbg_value(ptr @main.entries, !455, !DIExpression(), !464)
    #dbg_value(i32 %n.1.i.1, !460, !DIExpression(), !464)
    #dbg_value(i32 0, !461, !DIExpression(), !464)
    #dbg_value(i32 %n.1.i.1, !462, !DIExpression(DW_OP_constu, 1, DW_OP_minus, DW_OP_stack_value), !466)
  br label %land.rhs.i.i24, !dbg !467

for.body.i41.i:                                   ; preds = %for.body.i41.i.preheader, %for.body.i41.i
  %indvars.iv.i42.i = phi i64 [ %indvars.iv.next.i46.i, %for.body.i41.i ], [ 0, %for.body.i41.i.preheader ]
  %words.03.i.i = phi i64 [ %add7.i.i, %for.body.i41.i ], [ 0, %for.body.i41.i.preheader ]
  %letters.02.i.i = phi i64 [ %add.i.i22, %for.body.i41.i ], [ 0, %for.body.i41.i.preheader ]
    #dbg_value(i64 %indvars.iv.i42.i, !397, !DIExpression(), !468)
    #dbg_value(i64 %words.03.i.i, !396, !DIExpression(), !469)
    #dbg_value(i64 %letters.02.i.i, !395, !DIExpression(), !469)
  %arrayidx.i43.i = getelementptr inbounds nuw %struct.entry, ptr @main.entries, i64 %indvars.iv.i42.i, !dbg !470
  %call.i44.i = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %arrayidx.i43.i) #13, !dbg !473
  %count.i.i21 = getelementptr inbounds nuw i8, ptr %arrayidx.i43.i, i64 24, !dbg !474
  %27 = load i32, ptr %count.i.i21, align 8, !dbg !474, !tbaa !253
  %.fr.i.i = freeze i32 %27, !dbg !475
  %conv.i.i = sext i32 %.fr.i.i to i64, !dbg !475
  %mul.i45.i = mul nsw i64 %call.i44.i, %conv.i.i, !dbg !476
  %add.i.i22 = add nsw i64 %mul.i45.i, %letters.02.i.i, !dbg !477
    #dbg_value(i64 %add.i.i22, !395, !DIExpression(), !469)
  %add7.i.i = add i64 %words.03.i.i, %conv.i.i, !dbg !478
    #dbg_value(i64 %add7.i.i, !396, !DIExpression(), !469)
  %indvars.iv.next.i46.i = add nuw nsw i64 %indvars.iv.i42.i, 1, !dbg !479
    #dbg_value(i64 %indvars.iv.next.i46.i, !397, !DIExpression(), !468)
  %exitcond.not.i47.i = icmp eq i64 %indvars.iv.next.i46.i, %wide.trip.count.i.i, !dbg !480
  br i1 %exitcond.not.i47.i, label %for.cond.cleanup.i.i, label %for.body.i41.i, !dbg !481, !llvm.loop !482

mean_length.exit.i:                               ; preds = %collect.exit
  %call17.i = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.8, double noundef 0.000000e+00), !dbg !454
    #dbg_value(ptr @main.entries, !455, !DIExpression(), !464)
    #dbg_value(i32 %n.1.i.1, !460, !DIExpression(), !464)
    #dbg_value(i32 0, !461, !DIExpression(), !464)
    #dbg_value(i32 %n.1.i.1, !462, !DIExpression(DW_OP_constu, 1, DW_OP_minus, DW_OP_stack_value), !466)
  br label %report.exit, !dbg !484

land.rhs.i.i24:                                   ; preds = %for.body.i54.i, %for.cond.cleanup.i.i
  %indvars.iv.i50.i = phi i64 [ %wide.trip.count.i.i, %for.cond.cleanup.i.i ], [ %indvars.iv.next.i51.i, %for.body.i54.i ]
  %count.04.i.i = phi i32 [ 0, %for.cond.cleanup.i.i ], [ %inc.i55.i, %for.body.i54.i ]
  %indvars.iv.next.i51.i = add nsw i64 %indvars.iv.i50.i, -1, !dbg !486
    #dbg_value(i32 %count.04.i.i, !461, !DIExpression(), !464)
  %arrayidx.i52.i = getelementptr inbounds nuw %struct.entry, ptr @main.entries, i64 %indvars.iv.next.i51.i, !dbg !487
  %count1.i.i = getelementptr inbounds nuw i8, ptr %arrayidx.i52.i, i64 24, !dbg !488
  %28 = load i32, ptr %count1.i.i, align 8, !dbg !488, !tbaa !253
  %cmp2.i53.i = icmp eq i32 %28, 1, !dbg !489
  br i1 %cmp2.i53.i, label %for.body.i54.i, label %report.exit, !dbg !490

for.body.i54.i:                                   ; preds = %land.rhs.i.i24
  %inc.i55.i = add nuw nsw i32 %count.04.i.i, 1, !dbg !491
    #dbg_value(i32 %inc.i55.i, !461, !DIExpression(), !464)
    #dbg_value(i64 %indvars.iv.next.i51.i, !462, !DIExpression(DW_OP_constu, 1, DW_OP_minus, DW_OP_stack_value), !466)
  %exitcond.not.i56.i = icmp eq i32 %inc.i55.i, %n.1.i.1, !dbg !493
  br i1 %exitcond.not.i56.i, label %report.exit, label %land.rhs.i.i24, !dbg !494, !llvm.loop !495

report.exit:                                      ; preds = %land.rhs.i.i24, %for.body.i54.i, %mean_length.exit.i
  %count.0.lcssa.i.i = phi i32 [ 0, %mean_length.exit.i ], [ %n.1.i.1, %for.body.i54.i ], [ %count.04.i.i, %land.rhs.i.i24 ], !dbg !464
  %call19.i = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.9, i32 noundef %count.0.lcssa.i.i), !dbg !497
    #dbg_value(ptr @main.table, !498, !DIExpression(), !510)
    #dbg_value(ptr @.str, !503, !DIExpression(), !510)
    #dbg_value(ptr @.str, !221, !DIExpression(), !512)
    #dbg_value(ptr poison, !227, !DIExpression(), !514)
    #dbg_value(i32 poison, !226, !DIExpression(), !512)
  br label %for.body.i30, !dbg !515

for.body.i30:                                     ; preds = %report.exit, %for.inc.i35
  %index.06.in.i = phi i32 [ %add.i, %for.inc.i35 ], [ -1225551026, %report.exit ]
  %probe.05.i = phi i32 [ %inc.i36, %for.inc.i35 ], [ 0, %report.exit ]
  %index.06.i = and i32 %index.06.in.i, 255, !dbg !510
    #dbg_value(i32 %probe.05.i, !505, !DIExpression(), !516)
  %idxprom.i = zext nneg i32 %index.06.i to i64, !dbg !517
  %arrayidx.i31 = getelementptr inbounds nuw %struct.entry, ptr @main.table, i64 %idxprom.i, !dbg !518
    #dbg_value(ptr %arrayidx.i31, !507, !DIExpression(), !519)
  %count.i32 = getelementptr inbounds nuw i8, ptr %arrayidx.i31, i64 24, !dbg !520
  %29 = load i32, ptr %count.i32, align 4, !dbg !520, !tbaa !253
  %cmp1.i33 = icmp eq i32 %29, 0, !dbg !522
  br i1 %cmp1.i33, label %table_lookup.exit, label %if.end.i34, !dbg !523

if.end.i34:                                       ; preds = %for.body.i30
  %call3.i = tail call i32 @strcmp(ptr noundef nonnull dereferenceable(1) %arrayidx.i31, ptr noundef nonnull dereferenceable(4) @.str) #13, !dbg !524
  %cmp4.i = icmp eq i32 %call3.i, 0, !dbg !526
  br i1 %cmp4.i, label %table_lookup.exit, label %for.inc.i35, !dbg !527

for.inc.i35:                                      ; preds = %if.end.i34
  %add.i = add nuw nsw i32 %index.06.i, 1, !dbg !528
    #dbg_value(i32 %add.i, !504, !DIExpression(DW_OP_constu, 255, DW_OP_and, DW_OP_stack_value), !510)
  %inc.i36 = add nuw nsw i32 %probe.05.i, 1, !dbg !529
    #dbg_value(i32 %inc.i36, !505, !DIExpression(), !516)
  %exitcond.i = icmp eq i32 %inc.i36, 256, !dbg !530
  br i1 %exitcond.i, label %table_lookup.exit, label %for.body.i30, !dbg !531, !llvm.loop !532

table_lookup.exit:                                ; preds = %for.body.i30, %if.end.i34, %for.inc.i35
  %spec.select.i = phi i32 [ 0, %for.inc.i35 ], [ %29, %if.end.i34 ], [ 0, %for.body.i30 ]
    #dbg_value(i32 %spec.select.i, !98, !DIExpression(), !292)
    #dbg_value(ptr @main.table, !498, !DIExpression(), !534)
    #dbg_value(ptr @.str.1, !503, !DIExpression(), !534)
    #dbg_value(ptr @.str.1, !221, !DIExpression(), !536)
    #dbg_value(ptr poison, !227, !DIExpression(), !538)
    #dbg_value(i32 poison, !226, !DIExpression(), !536)
  br label %for.body.i46, !dbg !539

for.body.i46:                                     ; preds = %table_lookup.exit, %for.inc.i57
  %index.06.in.i47 = phi i32 [ %add.i58, %for.inc.i57 ], [ 108289031, %table_lookup.exit ]
  %probe.05.i48 = phi i32 [ %inc.i59, %for.inc.i57 ], [ 0, %table_lookup.exit ]
  %index.06.i49 = and i32 %index.06.in.i47, 255, !dbg !534
    #dbg_value(i32 %probe.05.i48, !505, !DIExpression(), !540)
  %idxprom.i50 = zext nneg i32 %index.06.i49 to i64, !dbg !541
  %arrayidx.i51 = getelementptr inbounds nuw %struct.entry, ptr @main.table, i64 %idxprom.i50, !dbg !542
    #dbg_value(ptr %arrayidx.i51, !507, !DIExpression(), !543)
  %count.i52 = getelementptr inbounds nuw i8, ptr %arrayidx.i51, i64 24, !dbg !544
  %30 = load i32, ptr %count.i52, align 4, !dbg !544, !tbaa !253
  %cmp1.i53 = icmp eq i32 %30, 0, !dbg !545
  br i1 %cmp1.i53, label %table_lookup.exit62, label %if.end.i54, !dbg !546

if.end.i54:                                       ; preds = %for.body.i46
  %call3.i55 = tail call i32 @strcmp(ptr noundef nonnull dereferenceable(1) %arrayidx.i51, ptr noundef nonnull dereferenceable(4) @.str.1) #13, !dbg !547
  %cmp4.i56 = icmp eq i32 %call3.i55, 0, !dbg !548
  br i1 %cmp4.i56, label %table_lookup.exit62, label %for.inc.i57, !dbg !549

for.inc.i57:                                      ; preds = %if.end.i54
  %add.i58 = add nuw nsw i32 %index.06.i49, 1, !dbg !550
    #dbg_value(i32 %add.i58, !504, !DIExpression(DW_OP_constu, 255, DW_OP_and, DW_OP_stack_value), !534)
  %inc.i59 = add nuw nsw i32 %probe.05.i48, 1, !dbg !551
    #dbg_value(i32 %inc.i59, !505, !DIExpression(), !540)
  %exitcond.i60 = icmp eq i32 %inc.i59, 256, !dbg !552
  br i1 %exitcond.i60, label %table_lookup.exit62, label %for.body.i46, !dbg !553, !llvm.loop !554

table_lookup.exit62:                              ; preds = %for.body.i46, %if.end.i54, %for.inc.i57
  %spec.select.i61 = phi i32 [ 0, %for.inc.i57 ], [ %30, %if.end.i54 ], [ 0, %for.body.i46 ]
    #dbg_value(i32 %spec.select.i61, !99, !DIExpression(), !292)
  %call4 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.2, i32 noundef %spec.select.i, i32 noundef %spec.select.i61), !dbg !556
  %cmp = icmp slt i32 %spec.select.i, 1, !dbg !557
  %cmp5 = icmp ne i32 %spec.select.i61, 0, !dbg !558
  %.not = or i1 %cmp, %cmp5, !dbg !559
  %cond = zext i1 %.not to i32, !dbg !559
  ret i32 %cond, !dbg !560
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(ptr captures(none)) #1

; Function Attrs: nofree nounwind
declare !dbg !561 noundef i32 @printf(ptr noundef readonly captures(none), ...) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(ptr captures(none)) #1

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr writeonly captures(none), i8, i64, i1 immarg) #3

; Function Attrs: nofree nounwind
declare !dbg !566 noundef i32 @fprintf(ptr noundef captures(none), ptr noundef readonly captures(none), ...) local_unnamed_addr #2

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
declare !dbg !624 ptr @__ctype_b_loc() local_unnamed_addr #4

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
declare !dbg !630 ptr @__ctype_tolower_loc() local_unnamed_addr #4

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare !dbg !637 ptr @strncpy(ptr noalias noundef returned writeonly, ptr noalias noundef readonly captures(none), i64 noundef) local_unnamed_addr #5

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: read)
declare !dbg !642 i32 @strcmp(ptr noundef captures(none), ptr noundef captures(none)) local_unnamed_addr #6

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #7

; Function Attrs: nofree
declare !dbg !645 void @qsort(ptr noundef, i64 noundef, i64 noundef, ptr noundef captures(none)) local_unnamed_addr #8

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: read) uwtable
define internal i32 @by_count(ptr noundef readonly captures(none) %a, ptr noundef readonly captures(none) %b) #9 !dbg !655 {
entry:
    #dbg_value(ptr %a, !657, !DIExpression(), !661)
    #dbg_value(ptr %b, !658, !DIExpression(), !661)
    #dbg_value(ptr %a, !659, !DIExpression(), !661)
    #dbg_value(ptr %b, !660, !DIExpression(), !661)
  %count = getelementptr inbounds nuw i8, ptr %a, i64 24, !dbg !662
  %0 = load i32, ptr %count, align 4, !dbg !662, !tbaa !253
  %count1 = getelementptr inbounds nuw i8, ptr %b, i64 24, !dbg !664
  %1 = load i32, ptr %count1, align 4, !dbg !664, !tbaa !253
  %cmp.not = icmp eq i32 %0, %1, !dbg !665
  br i1 %cmp.not, label %if.end, label %if.then, !dbg !666

if.then:                                          ; preds = %entry
  %sub = sub nsw i32 %1, %0, !dbg !667
  br label %cleanup, !dbg !669

if.end:                                           ; preds = %entry
  %first_seen = getelementptr inbounds nuw i8, ptr %a, i64 28, !dbg !670
  %2 = load i32, ptr %first_seen, align 4, !dbg !670, !tbaa !262
  %first_seen4 = getelementptr inbounds nuw i8, ptr %b, i64 28, !dbg !671
  %3 = load i32, ptr %first_seen4, align 4, !dbg !671, !tbaa !262
  %sub5 = sub nsw i32 %2, %3, !dbg !672
  br label %cleanup, !dbg !673

cleanup:                                          ; preds = %if.end, %if.then
  %retval.0 = phi i32 [ %sub, %if.then ], [ %sub5, %if.end ], !dbg !661
  ret i32 %retval.0, !dbg !674
}

; Function Attrs: nofree nounwind
declare !dbg !675 noundef i32 @putc(i32 noundef, ptr noundef captures(none)) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: read)
declare !dbg !678 i64 @strlen(ptr noundef captures(none)) local_unnamed_addr #6

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.umax.i64(i64, i64) #10

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.umin.i32(i32, i32) #10

attributes #0 = { nofree nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { nofree nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #4 = { mustprogress nofree nosync nounwind willreturn memory(none) "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #5 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #6 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: read) "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #7 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #8 = { nofree "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #9 = { mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: read) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #10 = { nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none) }
attributes #11 = { nounwind }
attributes #12 = { nounwind willreturn memory(none) }
attributes #13 = { nounwind willreturn memory(read) }
attributes #14 = { cold nounwind }

!llvm.dbg.cu = !{!7}
!llvm.module.flags = !{!104, !105, !106, !107, !108, !109, !110}
!llvm.ident = !{!111}
!llvm.errno.tbaa = !{!112}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(name: "table", scope: !2, file: !3, line: 186, type: !100, isLocal: true, isDefinition: true)
!2 = distinct !DISubprogram(name: "main", scope: !3, file: !3, line: 185, type: !4, scopeLine: 185, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !95, keyInstructions: true)
!3 = !DIFile(filename: "user-programs/word_frequency.c", directory: "/workspace", checksumkind: CSK_MD5, checksum: "afd9b995c56306632b4c51ff31edd173")
!4 = !DISubroutineType(types: !5)
!5 = !{!6}
!6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!7 = distinct !DICompileUnit(language: DW_LANG_C11, file: !8, producer: "clang version 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, enums: !9, retainedTypes: !26, globals: !36, splitDebugInlining: false, nameTableKind: None)
!8 = !DIFile(filename: "/workspace/user-programs/word_frequency.c", directory: "/workspace", checksumkind: CSK_MD5, checksum: "afd9b995c56306632b4c51ff31edd173")
!9 = !{!10}
!10 = !DICompositeType(tag: DW_TAG_enumeration_type, file: !11, line: 46, baseType: !12, size: 32, elements: !13)
!11 = !DIFile(filename: "/usr/include/ctype.h", directory: "", checksumkind: CSK_MD5, checksum: "43fd45dcf96e8fb7d8f14700096497c7")
!12 = !DIBasicType(name: "unsigned int", size: 32, encoding: DW_ATE_unsigned)
!13 = !{!14, !15, !16, !17, !18, !19, !20, !21, !22, !23, !24, !25}
!14 = !DIEnumerator(name: "_ISupper", value: 256)
!15 = !DIEnumerator(name: "_ISlower", value: 512)
!16 = !DIEnumerator(name: "_ISalpha", value: 1024)
!17 = !DIEnumerator(name: "_ISdigit", value: 2048)
!18 = !DIEnumerator(name: "_ISxdigit", value: 4096)
!19 = !DIEnumerator(name: "_ISspace", value: 8192)
!20 = !DIEnumerator(name: "_ISprint", value: 16384)
!21 = !DIEnumerator(name: "_ISgraph", value: 32768)
!22 = !DIEnumerator(name: "_ISblank", value: 1)
!23 = !DIEnumerator(name: "_IScntrl", value: 2)
!24 = !DIEnumerator(name: "_ISpunct", value: 4)
!25 = !DIEnumerator(name: "_ISalnum", value: 8)
!26 = !{!6, !27, !28, !29, !30, !33, !34, !35}
!27 = !DIBasicType(name: "unsigned char", size: 8, encoding: DW_ATE_unsigned_char)
!28 = !DIBasicType(name: "unsigned short", size: 16, encoding: DW_ATE_unsigned)
!29 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!30 = !DIDerivedType(tag: DW_TAG_typedef, name: "size_t", file: !31, line: 18, baseType: !32)
!31 = !DIFile(filename: "/opt/llvm/lib/clang/22/include/__stddef_size_t.h", directory: "", checksumkind: CSK_MD5, checksum: "2c44e821a2b1951cde2eb0fb2e656867")
!32 = !DIBasicType(name: "unsigned long", size: 64, encoding: DW_ATE_unsigned)
!33 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
!34 = !DIBasicType(name: "long", size: 64, encoding: DW_ATE_signed)
!35 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!36 = !{!0, !37, !50, !55, !57, !62, !67, !72, !76, !78, !83, !85, !90}
!37 = !DIGlobalVariableExpression(var: !38, expr: !DIExpression())
!38 = distinct !DIGlobalVariable(name: "entries", scope: !2, file: !3, line: 187, type: !39, isLocal: true, isDefinition: true)
!39 = !DICompositeType(tag: DW_TAG_array_type, baseType: !40, size: 65536, elements: !48)
!40 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "entry", file: !3, line: 12, size: 256, elements: !41)
!41 = !{!42, !46, !47}
!42 = !DIDerivedType(tag: DW_TAG_member, name: "word", scope: !40, file: !3, line: 13, baseType: !43, size: 192)
!43 = !DICompositeType(tag: DW_TAG_array_type, baseType: !29, size: 192, elements: !44)
!44 = !{!45}
!45 = !DISubrange(count: 24)
!46 = !DIDerivedType(tag: DW_TAG_member, name: "count", scope: !40, file: !3, line: 14, baseType: !6, size: 32, offset: 192)
!47 = !DIDerivedType(tag: DW_TAG_member, name: "first_seen", scope: !40, file: !3, line: 15, baseType: !6, size: 32, offset: 224)
!48 = !{!49}
!49 = !DISubrange(count: 256)
!50 = !DIGlobalVariableExpression(var: !51, expr: !DIExpression())
!51 = distinct !DIGlobalVariable(scope: null, file: !3, line: 192, type: !52, isLocal: true, isDefinition: true)
!52 = !DICompositeType(tag: DW_TAG_array_type, baseType: !29, size: 32, elements: !53)
!53 = !{!54}
!54 = !DISubrange(count: 4)
!55 = !DIGlobalVariableExpression(var: !56, expr: !DIExpression())
!56 = distinct !DIGlobalVariable(scope: null, file: !3, line: 193, type: !52, isLocal: true, isDefinition: true)
!57 = !DIGlobalVariableExpression(var: !58, expr: !DIExpression())
!58 = distinct !DIGlobalVariable(scope: null, file: !3, line: 194, type: !59, isLocal: true, isDefinition: true)
!59 = !DICompositeType(tag: DW_TAG_array_type, baseType: !29, size: 144, elements: !60)
!60 = !{!61}
!61 = !DISubrange(count: 18)
!62 = !DIGlobalVariableExpression(var: !63, expr: !DIExpression())
!63 = distinct !DIGlobalVariable(scope: null, file: !3, line: 102, type: !64, isLocal: true, isDefinition: true)
!64 = !DICompositeType(tag: DW_TAG_array_type, baseType: !29, size: 184, elements: !65)
!65 = !{!66}
!66 = !DISubrange(count: 23)
!67 = !DIGlobalVariableExpression(var: !68, expr: !DIExpression())
!68 = distinct !DIGlobalVariable(scope: null, file: !3, line: 24, type: !69, isLocal: true, isDefinition: true)
!69 = !DICompositeType(tag: DW_TAG_array_type, baseType: !29, size: 2280, elements: !70)
!70 = !{!71}
!71 = !DISubrange(count: 285)
!72 = !DIGlobalVariableExpression(var: !73, expr: !DIExpression())
!73 = distinct !DIGlobalVariable(name: "passage", scope: !7, file: !3, line: 23, type: !74, isLocal: true, isDefinition: true)
!74 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !75, size: 64)
!75 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !29)
!76 = !DIGlobalVariableExpression(var: !77, expr: !DIExpression())
!77 = distinct !DIGlobalVariable(scope: null, file: !3, line: 172, type: !64, isLocal: true, isDefinition: true)
!78 = !DIGlobalVariableExpression(var: !79, expr: !DIExpression())
!79 = distinct !DIGlobalVariable(scope: null, file: !3, line: 174, type: !80, isLocal: true, isDefinition: true)
!80 = !DICompositeType(tag: DW_TAG_array_type, baseType: !29, size: 88, elements: !81)
!81 = !{!82}
!82 = !DISubrange(count: 11)
!83 = !DIGlobalVariableExpression(var: !84, expr: !DIExpression())
!84 = distinct !DIGlobalVariable(scope: null, file: !3, line: 179, type: !59, isLocal: true, isDefinition: true)
!85 = !DIGlobalVariableExpression(var: !86, expr: !DIExpression())
!86 = distinct !DIGlobalVariable(scope: null, file: !3, line: 181, type: !87, isLocal: true, isDefinition: true)
!87 = !DICompositeType(tag: DW_TAG_array_type, baseType: !29, size: 216, elements: !88)
!88 = !{!89}
!89 = !DISubrange(count: 27)
!90 = !DIGlobalVariableExpression(var: !91, expr: !DIExpression())
!91 = distinct !DIGlobalVariable(scope: null, file: !3, line: 182, type: !92, isLocal: true, isDefinition: true)
!92 = !DICompositeType(tag: DW_TAG_array_type, baseType: !29, size: 168, elements: !93)
!93 = !{!94}
!94 = !DISubrange(count: 21)
!95 = !{!96, !97, !98, !99}
!96 = !DILocalVariable(name: "total", scope: !2, file: !3, line: 189, type: !6)
!97 = !DILocalVariable(name: "n", scope: !2, file: !3, line: 190, type: !6)
!98 = !DILocalVariable(name: "foxes", scope: !2, file: !3, line: 192, type: !6)
!99 = !DILocalVariable(name: "cats", scope: !2, file: !3, line: 193, type: !6)
!100 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "table", file: !3, line: 18, size: 65568, elements: !101)
!101 = !{!102, !103}
!102 = !DIDerivedType(tag: DW_TAG_member, name: "slots", scope: !100, file: !3, line: 19, baseType: !39, size: 65536)
!103 = !DIDerivedType(tag: DW_TAG_member, name: "used", scope: !100, file: !3, line: 20, baseType: !6, size: 32, offset: 65536)
!104 = !{i32 7, !"Dwarf Version", i32 5}
!105 = !{i32 2, !"Debug Info Version", i32 3}
!106 = !{i32 1, !"wchar_size", i32 4}
!107 = !{i32 8, !"PIC Level", i32 2}
!108 = !{i32 7, !"PIE Level", i32 2}
!109 = !{i32 7, !"uwtable", i32 2}
!110 = !{i32 7, !"debug-info-assignment-tracking", i1 true}
!111 = !{!"clang version 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)"}
!112 = !{!113, !113, i64 0}
!113 = !{!"int", !114, i64 0}
!114 = !{!"omnipotent char", !115, i64 0}
!115 = !{!"Simple C/C++ TBAA"}
!116 = distinct !DIAssignID()
!117 = !DILocalVariable(name: "table", arg: 1, scope: !118, file: !3, line: 39, type: !121)
!118 = distinct !DISubprogram(name: "table_init", scope: !3, file: !3, line: 39, type: !119, scopeLine: 39, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !122, keyInstructions: true)
!119 = !DISubroutineType(types: !120)
!120 = !{null, !121}
!121 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !100, size: 64)
!122 = !{!117}
!123 = !DILocation(line: 0, scope: !118, inlinedAt: !124)
!124 = distinct !DILocation(line: 188, column: 5, scope: !2)
!125 = !DILocation(line: 40, column: 5, scope: !118, inlinedAt: !124, atomGroup: 1, atomRank: 1)
!126 = !DILocalVariable(name: "word", scope: !127, file: !3, line: 98, type: !43)
!127 = distinct !DISubprogram(name: "count_words", scope: !3, file: !3, line: 97, type: !128, scopeLine: 97, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !130, keyInstructions: true)
!128 = !DISubroutineType(types: !129)
!129 = !{!6, !121, !74}
!130 = !{!131, !132, !126, !133}
!131 = !DILocalVariable(name: "table", arg: 1, scope: !127, file: !3, line: 97, type: !121)
!132 = !DILocalVariable(name: "text", arg: 2, scope: !127, file: !3, line: 97, type: !74)
!133 = !DILocalVariable(name: "position", scope: !127, file: !3, line: 99, type: !6)
!134 = !DILocation(line: 0, scope: !127, inlinedAt: !135)
!135 = distinct !DILocation(line: 189, column: 17, scope: !2)
!136 = !DILocation(line: 98, column: 5, scope: !127, inlinedAt: !135)
!137 = !DILocation(line: 100, column: 5, scope: !127, inlinedAt: !135)
!138 = !DILocalVariable(name: "text", arg: 1, scope: !139, file: !3, line: 80, type: !142)
!139 = distinct !DISubprogram(name: "next_word", scope: !3, file: !3, line: 80, type: !140, scopeLine: 80, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !144, keyInstructions: true)
!140 = !DISubroutineType(types: !141)
!141 = !{!6, !142, !143}
!142 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !74, size: 64)
!143 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !29, size: 64)
!144 = !{!138, !145, !146, !147, !148}
!145 = !DILocalVariable(name: "word", arg: 2, scope: !139, file: !3, line: 80, type: !143)
!146 = !DILocalVariable(name: "p", scope: !139, file: !3, line: 81, type: !74)
!147 = !DILocalVariable(name: "length", scope: !139, file: !3, line: 85, type: !6)
!148 = !DILocalVariable(name: "__res", scope: !149, file: !3, line: 88, type: !6)
!149 = distinct !DILexicalBlock(scope: !150, file: !3, line: 88, column: 36)
!150 = distinct !DILexicalBlock(scope: !151, file: !3, line: 87, column: 36)
!151 = distinct !DILexicalBlock(scope: !152, file: !3, line: 87, column: 13)
!152 = distinct !DILexicalBlock(scope: !139, file: !3, line: 86, column: 40)
!153 = !DILocation(line: 0, scope: !139, inlinedAt: !154)
!154 = distinct !DILocation(line: 100, column: 12, scope: !127, inlinedAt: !135)
!155 = !DILocation(line: 82, column: 12, scope: !139, inlinedAt: !154)
!156 = !{!114, !114, i64 0}
!157 = !DILocation(line: 82, column: 15, scope: !139, inlinedAt: !154, atomGroup: 19, atomRank: 2)
!158 = !DILocation(line: 86, column: 12, scope: !139, inlinedAt: !154)
!159 = !{!160, !160, i64 0}
!160 = !{!"p1 short", !161, i64 0}
!161 = !{!"any pointer", !114, i64 0}
!162 = !DILocation(line: 82, column: 23, scope: !139, inlinedAt: !154, atomGroup: 19, atomRank: 1)
!163 = !DILocation(line: 82, column: 27, scope: !139, inlinedAt: !154)
!164 = !{!165, !165, i64 0}
!165 = !{!"short", !114, i64 0}
!166 = !DILocation(line: 82, column: 26, scope: !139, inlinedAt: !154)
!167 = !DILocation(line: 82, column: 5, scope: !139, inlinedAt: !154, atomGroup: 3, atomRank: 1)
!168 = !DILocation(line: 83, column: 10, scope: !169, inlinedAt: !154, atomGroup: 4, atomRank: 2)
!169 = distinct !DILexicalBlock(scope: !139, file: !3, line: 82, column: 55)
!170 = !DILocation(line: 82, column: 15, scope: !139, inlinedAt: !154, atomGroup: 2, atomRank: 2)
!171 = !DILocation(line: 82, column: 23, scope: !139, inlinedAt: !154, atomGroup: 2, atomRank: 1)
!172 = distinct !{!172, !173, !174, !175}
!173 = !DILocation(line: 82, column: 5, scope: !139, inlinedAt: !154)
!174 = !DILocation(line: 84, column: 5, scope: !139, inlinedAt: !154)
!175 = !{!"llvm.loop.mustprogress"}
!176 = distinct !{!176, !173, !174, !175}
!177 = !DILocation(line: 86, column: 35, scope: !139, inlinedAt: !154)
!178 = !DILocation(line: 86, column: 5, scope: !139, inlinedAt: !154, atomGroup: 20, atomRank: 1)
!179 = !DILocation(line: 86, column: 5, scope: !139, inlinedAt: !154, atomGroup: 21, atomRank: 1)
!180 = !DILocation(line: 87, column: 20, scope: !151, inlinedAt: !154, atomGroup: 8, atomRank: 2)
!181 = !DILocation(line: 87, column: 20, scope: !151, inlinedAt: !154, atomGroup: 8, atomRank: 1)
!182 = !DILocation(line: 88, column: 36, scope: !183, inlinedAt: !154)
!183 = distinct !DILexicalBlock(scope: !149, file: !3, line: 88, column: 36)
!184 = !{!185, !185, i64 0}
!185 = !{!"p1 int", !161, i64 0}
!186 = !DILocation(line: 88, column: 36, scope: !183, inlinedAt: !154, atomGroup: 9, atomRank: 2)
!187 = !DILocation(line: 0, scope: !149, inlinedAt: !154)
!188 = !DILocation(line: 88, column: 30, scope: !150, inlinedAt: !154, atomGroup: 9, atomRank: 2)
!189 = !DILocation(line: 88, column: 24, scope: !150, inlinedAt: !154, atomGroup: 10, atomRank: 2)
!190 = !DILocation(line: 88, column: 13, scope: !150, inlinedAt: !154)
!191 = !DILocation(line: 88, column: 28, scope: !150, inlinedAt: !154, atomGroup: 9, atomRank: 1)
!192 = !DILocation(line: 89, column: 9, scope: !150, inlinedAt: !154)
!193 = !DILocation(line: 90, column: 10, scope: !152, inlinedAt: !154, atomGroup: 11, atomRank: 2)
!194 = !DILocation(line: 86, column: 5, scope: !139, inlinedAt: !154, atomGroup: 6, atomRank: 1)
!195 = !DILocation(line: 86, column: 5, scope: !139, inlinedAt: !154, atomGroup: 7, atomRank: 1)
!196 = distinct !{!196, !197, !198, !175}
!197 = !DILocation(line: 86, column: 5, scope: !139, inlinedAt: !154)
!198 = !DILocation(line: 91, column: 5, scope: !139, inlinedAt: !154)
!199 = !DILocation(line: 92, column: 5, scope: !139, inlinedAt: !154)
!200 = !DILocation(line: 92, column: 18, scope: !139, inlinedAt: !154, atomGroup: 12, atomRank: 1)
!201 = !DILocation(line: 100, column: 35, scope: !127, inlinedAt: !135, atomGroup: 2, atomRank: 1)
!202 = !DILocation(line: 100, column: 5, scope: !127, inlinedAt: !135, atomGroup: 3, atomRank: 1)
!203 = !DILocalVariable(name: "table", arg: 1, scope: !204, file: !3, line: 44, type: !121)
!204 = distinct !DISubprogram(name: "table_add", scope: !3, file: !3, line: 44, type: !205, scopeLine: 44, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !207, keyInstructions: true)
!205 = !DISubroutineType(types: !206)
!206 = !{!6, !121, !74, !6}
!207 = !{!203, !208, !209, !210, !211, !213}
!208 = !DILocalVariable(name: "word", arg: 2, scope: !204, file: !3, line: 44, type: !74)
!209 = !DILocalVariable(name: "position", arg: 3, scope: !204, file: !3, line: 44, type: !6)
!210 = !DILocalVariable(name: "index", scope: !204, file: !3, line: 45, type: !12)
!211 = !DILocalVariable(name: "probe", scope: !212, file: !3, line: 46, type: !6)
!212 = distinct !DILexicalBlock(scope: !204, file: !3, line: 46, column: 5)
!213 = !DILocalVariable(name: "slot", scope: !214, file: !3, line: 47, type: !216)
!214 = distinct !DILexicalBlock(scope: !215, file: !3, line: 46, column: 54)
!215 = distinct !DILexicalBlock(scope: !212, file: !3, line: 46, column: 5)
!216 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !40, size: 64)
!217 = !DILocation(line: 0, scope: !204, inlinedAt: !218)
!218 = distinct !DILocation(line: 101, column: 13, scope: !219, inlinedAt: !135)
!219 = distinct !DILexicalBlock(scope: !220, file: !3, line: 101, column: 13)
!220 = distinct !DILexicalBlock(scope: !127, file: !3, line: 100, column: 40)
!221 = !DILocalVariable(name: "word", arg: 1, scope: !222, file: !3, line: 30, type: !74)
!222 = distinct !DISubprogram(name: "hash_word", scope: !3, file: !3, line: 30, type: !223, scopeLine: 30, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !225, keyInstructions: true)
!223 = !DISubroutineType(types: !224)
!224 = !{!12, !74}
!225 = !{!221, !226, !227}
!226 = !DILocalVariable(name: "hash", scope: !222, file: !3, line: 31, type: !12)
!227 = !DILocalVariable(name: "p", scope: !228, file: !3, line: 32, type: !74)
!228 = distinct !DILexicalBlock(scope: !222, file: !3, line: 32, column: 5)
!229 = !DILocation(line: 0, scope: !222, inlinedAt: !230)
!230 = distinct !DILocation(line: 45, column: 26, scope: !204, inlinedAt: !218)
!231 = !DILocation(line: 0, scope: !228, inlinedAt: !230)
!232 = !DILocation(line: 32, column: 32, scope: !233, inlinedAt: !230)
!233 = distinct !DILexicalBlock(scope: !228, file: !3, line: 32, column: 5)
!234 = !DILocation(line: 32, column: 35, scope: !233, inlinedAt: !230, atomGroup: 22, atomRank: 1)
!235 = !DILocation(line: 32, column: 5, scope: !228, inlinedAt: !230, atomGroup: 23, atomRank: 1)
!236 = !DILocation(line: 33, column: 17, scope: !237, inlinedAt: !230)
!237 = distinct !DILexicalBlock(scope: !233, file: !3, line: 32, column: 49)
!238 = !DILocation(line: 33, column: 14, scope: !237, inlinedAt: !230, atomGroup: 5, atomRank: 2)
!239 = !DILocation(line: 34, column: 14, scope: !237, inlinedAt: !230, atomGroup: 6, atomRank: 2)
!240 = !DILocation(line: 32, column: 45, scope: !233, inlinedAt: !230, atomGroup: 7, atomRank: 2)
!241 = !DILocation(line: 32, column: 35, scope: !233, inlinedAt: !230, atomGroup: 3, atomRank: 1)
!242 = !DILocation(line: 32, column: 5, scope: !228, inlinedAt: !230, atomGroup: 4, atomRank: 1)
!243 = distinct !{!243, !244, !245, !175}
!244 = !DILocation(line: 32, column: 5, scope: !228, inlinedAt: !230)
!245 = !DILocation(line: 35, column: 5, scope: !228, inlinedAt: !230)
!246 = !DILocation(line: 46, column: 5, scope: !212, inlinedAt: !218)
!247 = !DILocation(line: 0, scope: !212, inlinedAt: !218)
!248 = !DILocation(line: 47, column: 31, scope: !214, inlinedAt: !218)
!249 = !DILocation(line: 47, column: 31, scope: !214, inlinedAt: !218, atomGroup: 5, atomRank: 2)
!250 = !DILocation(line: 0, scope: !214, inlinedAt: !218)
!251 = !DILocation(line: 48, column: 19, scope: !252, inlinedAt: !218)
!252 = distinct !DILexicalBlock(scope: !214, file: !3, line: 48, column: 13)
!253 = !{!254, !113, i64 24}
!254 = !{!"entry", !114, i64 0, !113, i64 24, !113, i64 28}
!255 = !DILocation(line: 48, column: 25, scope: !252, inlinedAt: !218, atomGroup: 6, atomRank: 2)
!256 = !DILocation(line: 48, column: 25, scope: !252, inlinedAt: !218, atomGroup: 6, atomRank: 1)
!257 = !DILocation(line: 49, column: 13, scope: !258, inlinedAt: !218)
!258 = distinct !DILexicalBlock(scope: !252, file: !3, line: 48, column: 31)
!259 = !DILocation(line: 50, column: 25, scope: !258, inlinedAt: !218, atomGroup: 7, atomRank: 1)
!260 = !DILocation(line: 51, column: 19, scope: !258, inlinedAt: !218)
!261 = !DILocation(line: 51, column: 30, scope: !258, inlinedAt: !218, atomGroup: 8, atomRank: 1)
!262 = !{!254, !113, i64 28}
!263 = !DILocation(line: 52, column: 24, scope: !258, inlinedAt: !218, atomGroup: 9, atomRank: 2)
!264 = !DILocation(line: 52, column: 24, scope: !258, inlinedAt: !218, atomGroup: 9, atomRank: 1)
!265 = !{!266, !113, i64 8192}
!266 = !{!"table", !114, i64 0, !113, i64 8192}
!267 = !DILocation(line: 53, column: 13, scope: !258, inlinedAt: !218, atomGroup: 10, atomRank: 1)
!268 = !DILocation(line: 55, column: 13, scope: !269, inlinedAt: !218)
!269 = distinct !DILexicalBlock(scope: !214, file: !3, line: 55, column: 13)
!270 = !DILocation(line: 55, column: 38, scope: !269, inlinedAt: !218, atomGroup: 11, atomRank: 2)
!271 = !DILocation(line: 55, column: 38, scope: !269, inlinedAt: !218, atomGroup: 11, atomRank: 1)
!272 = !DILocation(line: 56, column: 24, scope: !273, inlinedAt: !218, atomGroup: 12, atomRank: 2)
!273 = distinct !DILexicalBlock(scope: !269, file: !3, line: 55, column: 44)
!274 = !DILocation(line: 56, column: 24, scope: !273, inlinedAt: !218, atomGroup: 12, atomRank: 1)
!275 = !DILocation(line: 57, column: 13, scope: !273, inlinedAt: !218, atomGroup: 13, atomRank: 1)
!276 = !DILocation(line: 59, column: 24, scope: !214, inlinedAt: !218)
!277 = !DILocation(line: 46, column: 50, scope: !215, inlinedAt: !218, atomGroup: 15, atomRank: 2)
!278 = !DILocation(line: 46, column: 31, scope: !215, inlinedAt: !218, atomGroup: 3, atomRank: 1)
!279 = !DILocation(line: 46, column: 5, scope: !212, inlinedAt: !218, atomGroup: 4, atomRank: 1)
!280 = distinct !{!280, !246, !281, !175}
!281 = !DILocation(line: 60, column: 5, scope: !212, inlinedAt: !218)
!282 = !DILocation(line: 102, column: 21, scope: !283, inlinedAt: !135)
!283 = distinct !DILexicalBlock(scope: !219, file: !3, line: 101, column: 51)
!284 = !{!285, !285, i64 0}
!285 = !{!"p1 _ZTS8_IO_FILE", !161, i64 0}
!286 = !DILocation(line: 102, column: 13, scope: !283, inlinedAt: !135)
!287 = !DILocation(line: 103, column: 13, scope: !283, inlinedAt: !135, atomGroup: 5, atomRank: 1)
!288 = !DILocation(line: 105, column: 17, scope: !220, inlinedAt: !135, atomGroup: 6, atomRank: 2)
!289 = distinct !{!289, !137, !290, !175}
!290 = !DILocation(line: 106, column: 5, scope: !127, inlinedAt: !135)
!291 = !DILocation(line: 108, column: 1, scope: !127, inlinedAt: !135)
!292 = !DILocation(line: 0, scope: !2)
!293 = !DILocalVariable(name: "table", arg: 1, scope: !294, file: !3, line: 120, type: !297)
!294 = distinct !DISubprogram(name: "collect", scope: !3, file: !3, line: 120, type: !295, scopeLine: 120, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !299, keyInstructions: true)
!295 = !DISubroutineType(types: !296)
!296 = !{!6, !297, !216}
!297 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !298, size: 64)
!298 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !100)
!299 = !{!293, !300, !301, !302}
!300 = !DILocalVariable(name: "out", arg: 2, scope: !294, file: !3, line: 120, type: !216)
!301 = !DILocalVariable(name: "n", scope: !294, file: !3, line: 121, type: !6)
!302 = !DILocalVariable(name: "i", scope: !303, file: !3, line: 122, type: !6)
!303 = distinct !DILexicalBlock(scope: !294, file: !3, line: 122, column: 5)
!304 = !DILocation(line: 0, scope: !294, inlinedAt: !305)
!305 = distinct !DILocation(line: 190, column: 13, scope: !2)
!306 = !DILocation(line: 0, scope: !303, inlinedAt: !305)
!307 = !DILocation(line: 122, column: 5, scope: !303, inlinedAt: !305, atomGroup: 30, atomRank: 1)
!308 = !DILocation(line: 123, column: 13, scope: !309, inlinedAt: !305)
!309 = distinct !DILexicalBlock(scope: !310, file: !3, line: 123, column: 13)
!310 = distinct !DILexicalBlock(scope: !311, file: !3, line: 122, column: 42)
!311 = distinct !DILexicalBlock(scope: !303, file: !3, line: 122, column: 5)
!312 = !DILocation(line: 123, column: 29, scope: !309, inlinedAt: !305)
!313 = !DILocation(line: 123, column: 35, scope: !309, inlinedAt: !305, atomGroup: 5, atomRank: 2)
!314 = !DILocation(line: 123, column: 35, scope: !309, inlinedAt: !305, atomGroup: 5, atomRank: 1)
!315 = !DILocation(line: 124, column: 18, scope: !316, inlinedAt: !305, atomGroup: 7, atomRank: 2)
!316 = distinct !DILexicalBlock(scope: !309, file: !3, line: 123, column: 40)
!317 = !DILocation(line: 124, column: 13, scope: !316, inlinedAt: !305)
!318 = !DILocation(line: 124, column: 24, scope: !316, inlinedAt: !305, atomGroup: 6, atomRank: 1)
!319 = !{i64 0, i64 24, !156, i64 24, i64 4, !112, i64 28, i64 4, !112}
!320 = !DILocation(line: 125, column: 9, scope: !316, inlinedAt: !305)
!321 = !DILocation(line: 123, column: 35, scope: !309, inlinedAt: !305, atomGroup: 48, atomRank: 2)
!322 = !DILocation(line: 123, column: 35, scope: !309, inlinedAt: !305, atomGroup: 48, atomRank: 1)
!323 = !DILocation(line: 124, column: 18, scope: !316, inlinedAt: !305, atomGroup: 49, atomRank: 2)
!324 = !DILocation(line: 124, column: 24, scope: !316, inlinedAt: !305, atomGroup: 50, atomRank: 1)
!325 = !DILocation(line: 122, column: 38, scope: !311, inlinedAt: !305, atomGroup: 51, atomRank: 2)
!326 = !DILocation(line: 122, column: 23, scope: !311, inlinedAt: !305, atomGroup: 52, atomRank: 1)
!327 = !DILocation(line: 122, column: 5, scope: !303, inlinedAt: !305, atomGroup: 53, atomRank: 1)
!328 = distinct !{!328, !329, !330, !175}
!329 = !DILocation(line: 122, column: 5, scope: !303, inlinedAt: !305)
!330 = !DILocation(line: 126, column: 5, scope: !303, inlinedAt: !305)
!331 = !DILocation(line: 127, column: 16, scope: !294, inlinedAt: !305)
!332 = !DILocation(line: 127, column: 5, scope: !294, inlinedAt: !305)
!333 = !DILocalVariable(name: "entries", arg: 1, scope: !334, file: !3, line: 170, type: !337)
!334 = distinct !DISubprogram(name: "report", scope: !3, file: !3, line: 170, type: !335, scopeLine: 170, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !339, keyInstructions: true)
!335 = !DISubroutineType(types: !336)
!336 = !{null, !337, !6, !6}
!337 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !338, size: 64)
!338 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !40)
!339 = !{!333, !340, !341, !342, !343, !345}
!340 = !DILocalVariable(name: "n", arg: 2, scope: !334, file: !3, line: 170, type: !6)
!341 = !DILocalVariable(name: "total", arg: 3, scope: !334, file: !3, line: 170, type: !6)
!342 = !DILocalVariable(name: "shown", scope: !334, file: !3, line: 171, type: !6)
!343 = !DILocalVariable(name: "i", scope: !344, file: !3, line: 173, type: !6)
!344 = distinct !DILexicalBlock(scope: !334, file: !3, line: 173, column: 5)
!345 = !DILocalVariable(name: "word", scope: !334, file: !3, line: 177, type: !337)
!346 = !DILocation(line: 0, scope: !334, inlinedAt: !347)
!347 = distinct !DILocation(line: 191, column: 5, scope: !2)
!348 = !DILocation(line: 172, column: 5, scope: !334, inlinedAt: !347)
!349 = !DILocation(line: 0, scope: !344, inlinedAt: !347)
!350 = !DILocation(line: 173, column: 23, scope: !351, inlinedAt: !347, atomGroup: 44, atomRank: 1)
!351 = distinct !DILexicalBlock(scope: !344, file: !3, line: 173, column: 5)
!352 = !DILocation(line: 173, column: 5, scope: !344, inlinedAt: !347, atomGroup: 45, atomRank: 1)
!353 = !DILocation(line: 171, column: 17, scope: !334, inlinedAt: !347, atomGroup: 2, atomRank: 1)
!354 = !DILocation(line: 173, column: 23, scope: !351, inlinedAt: !347, atomGroup: 4, atomRank: 1)
!355 = !DILocation(line: 173, column: 5, scope: !344, inlinedAt: !347)
!356 = !DILocalVariable(name: "entries", arg: 1, scope: !357, file: !3, line: 141, type: !337)
!357 = distinct !DISubprogram(name: "longest", scope: !3, file: !3, line: 141, type: !358, scopeLine: 141, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !360, keyInstructions: true)
!358 = !DISubroutineType(types: !359)
!359 = !{!337, !337, !6}
!360 = !{!356, !361, !362, !363, !364, !366}
!361 = !DILocalVariable(name: "n", arg: 2, scope: !357, file: !3, line: 141, type: !6)
!362 = !DILocalVariable(name: "best", scope: !357, file: !3, line: 142, type: !337)
!363 = !DILocalVariable(name: "best_length", scope: !357, file: !3, line: 143, type: !30)
!364 = !DILocalVariable(name: "i", scope: !365, file: !3, line: 144, type: !6)
!365 = distinct !DILexicalBlock(scope: !357, file: !3, line: 144, column: 5)
!366 = !DILocalVariable(name: "length", scope: !367, file: !3, line: 145, type: !30)
!367 = distinct !DILexicalBlock(scope: !368, file: !3, line: 144, column: 33)
!368 = distinct !DILexicalBlock(scope: !365, file: !3, line: 144, column: 5)
!369 = !DILocation(line: 0, scope: !357, inlinedAt: !370)
!370 = distinct !DILocation(line: 177, column: 32, scope: !334, inlinedAt: !347)
!371 = !DILocation(line: 0, scope: !365, inlinedAt: !370)
!372 = !DILocation(line: 144, column: 23, scope: !368, inlinedAt: !370, atomGroup: 4, atomRank: 1)
!373 = !DILocation(line: 144, column: 5, scope: !365, inlinedAt: !370)
!374 = !DILocation(line: 145, column: 32, scope: !367, inlinedAt: !370)
!375 = !DILocation(line: 145, column: 25, scope: !367, inlinedAt: !370, atomGroup: 6, atomRank: 2)
!376 = !DILocation(line: 0, scope: !367, inlinedAt: !370)
!377 = !DILocation(line: 146, column: 20, scope: !378, inlinedAt: !370, atomGroup: 7, atomRank: 2)
!378 = distinct !DILexicalBlock(scope: !367, file: !3, line: 146, column: 13)
!379 = !DILocation(line: 146, column: 20, scope: !378, inlinedAt: !370, atomGroup: 7, atomRank: 1)
!380 = !DILocation(line: 144, column: 29, scope: !368, inlinedAt: !370, atomGroup: 10, atomRank: 2)
!381 = !DILocation(line: 144, column: 5, scope: !365, inlinedAt: !370, atomGroup: 5, atomRank: 1)
!382 = distinct !{!382, !373, !383, !175}
!383 = !DILocation(line: 150, column: 5, scope: !365, inlinedAt: !370)
!384 = !DILocation(line: 178, column: 14, scope: !385, inlinedAt: !347, atomGroup: 9, atomRank: 2)
!385 = distinct !DILexicalBlock(scope: !334, file: !3, line: 178, column: 9)
!386 = !DILocation(line: 178, column: 14, scope: !385, inlinedAt: !347, atomGroup: 9, atomRank: 1)
!387 = !DILocation(line: 134, column: 5, scope: !388, inlinedAt: !398)
!388 = distinct !DILexicalBlock(scope: !389, file: !3, line: 134, column: 5)
!389 = distinct !DISubprogram(name: "mean_length", scope: !3, file: !3, line: 131, type: !390, scopeLine: 131, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !392, keyInstructions: true)
!390 = !DISubroutineType(types: !391)
!391 = !{!35, !337, !6}
!392 = !{!393, !394, !395, !396, !397}
!393 = !DILocalVariable(name: "entries", arg: 1, scope: !389, file: !3, line: 131, type: !337)
!394 = !DILocalVariable(name: "n", arg: 2, scope: !389, file: !3, line: 131, type: !6)
!395 = !DILocalVariable(name: "letters", scope: !389, file: !3, line: 132, type: !34)
!396 = !DILocalVariable(name: "words", scope: !389, file: !3, line: 133, type: !34)
!397 = !DILocalVariable(name: "i", scope: !388, file: !3, line: 134, type: !6)
!398 = distinct !DILocation(line: 181, column: 43, scope: !334, inlinedAt: !347)
!399 = !DILocation(line: 174, column: 30, scope: !400, inlinedAt: !347)
!400 = distinct !DILexicalBlock(scope: !351, file: !3, line: 173, column: 37)
!401 = !DILocation(line: 174, column: 58, scope: !400, inlinedAt: !347)
!402 = !DILocation(line: 174, column: 9, scope: !400, inlinedAt: !347)
!403 = !DILocation(line: 175, column: 48, scope: !400, inlinedAt: !347)
!404 = !DILocalVariable(name: "count", arg: 1, scope: !405, file: !3, line: 162, type: !6)
!405 = distinct !DISubprogram(name: "print_bar", scope: !3, file: !3, line: 162, type: !406, scopeLine: 162, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !408, keyInstructions: true)
!406 = !DISubroutineType(types: !407)
!407 = !{null, !6, !6}
!408 = !{!404, !409, !410, !411}
!409 = !DILocalVariable(name: "widest", arg: 2, scope: !405, file: !3, line: 162, type: !6)
!410 = !DILocalVariable(name: "width", scope: !405, file: !3, line: 163, type: !6)
!411 = !DILocalVariable(name: "i", scope: !412, file: !3, line: 164, type: !6)
!412 = distinct !DILexicalBlock(scope: !405, file: !3, line: 164, column: 5)
!413 = !DILocation(line: 0, scope: !405, inlinedAt: !414)
!414 = distinct !DILocation(line: 175, column: 9, scope: !400, inlinedAt: !347)
!415 = !DILocation(line: 163, column: 24, scope: !405, inlinedAt: !414, atomGroup: 2, atomRank: 2)
!416 = !DILocation(line: 163, column: 17, scope: !405, inlinedAt: !414, atomGroup: 2, atomRank: 1)
!417 = !DILocation(line: 175, column: 30, scope: !400, inlinedAt: !347)
!418 = !DILocation(line: 163, column: 36, scope: !405, inlinedAt: !414)
!419 = !DILocation(line: 163, column: 41, scope: !405, inlinedAt: !414)
!420 = !DILocation(line: 0, scope: !412, inlinedAt: !414)
!421 = !DILocation(line: 164, column: 23, scope: !422, inlinedAt: !414, atomGroup: 33, atomRank: 1)
!422 = distinct !DILexicalBlock(scope: !412, file: !3, line: 164, column: 5)
!423 = !DILocation(line: 164, column: 5, scope: !412, inlinedAt: !414, atomGroup: 34, atomRank: 1)
!424 = !DILocalVariable(name: "__c", arg: 1, scope: !425, file: !426, line: 82, type: !6)
!425 = distinct !DISubprogram(name: "putchar", scope: !426, file: !426, line: 82, type: !427, scopeLine: 83, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !429, keyInstructions: true)
!426 = !DIFile(filename: "/usr/include/x86_64-linux-gnu/bits/stdio.h", directory: "", checksumkind: CSK_MD5, checksum: "482f6cda8975d1ad2408a10cdc1e14ac")
!427 = !DISubroutineType(types: !428)
!428 = !{!6, !6}
!429 = !{!424}
!430 = !DILocation(line: 0, scope: !425, inlinedAt: !431)
!431 = distinct !DILocation(line: 165, column: 9, scope: !432, inlinedAt: !414)
!432 = distinct !DILexicalBlock(scope: !422, file: !3, line: 164, column: 37)
!433 = !DILocation(line: 84, column: 21, scope: !425, inlinedAt: !431)
!434 = !DILocation(line: 84, column: 10, scope: !425, inlinedAt: !431, atomGroup: 1, atomRank: 2)
!435 = !DILocation(line: 164, column: 33, scope: !422, inlinedAt: !414, atomGroup: 6, atomRank: 2)
!436 = !DILocation(line: 164, column: 23, scope: !422, inlinedAt: !414, atomGroup: 4, atomRank: 1)
!437 = !DILocation(line: 164, column: 5, scope: !412, inlinedAt: !414, atomGroup: 5, atomRank: 1)
!438 = distinct !{!438, !439, !440, !175}
!439 = !DILocation(line: 164, column: 5, scope: !412, inlinedAt: !414)
!440 = !DILocation(line: 166, column: 5, scope: !412, inlinedAt: !414)
!441 = !DILocation(line: 0, scope: !425, inlinedAt: !442)
!442 = distinct !DILocation(line: 167, column: 5, scope: !405, inlinedAt: !414)
!443 = !DILocation(line: 84, column: 21, scope: !425, inlinedAt: !442)
!444 = !DILocation(line: 84, column: 10, scope: !425, inlinedAt: !442, atomGroup: 1, atomRank: 2)
!445 = !DILocation(line: 173, column: 33, scope: !351, inlinedAt: !347, atomGroup: 6, atomRank: 2)
!446 = !DILocation(line: 173, column: 5, scope: !344, inlinedAt: !347, atomGroup: 5, atomRank: 1)
!447 = distinct !{!447, !355, !448, !175}
!448 = !DILocation(line: 176, column: 5, scope: !344, inlinedAt: !347)
!449 = !DILocation(line: 179, column: 9, scope: !450, inlinedAt: !347)
!450 = distinct !DILexicalBlock(scope: !385, file: !3, line: 178, column: 23)
!451 = !DILocation(line: 180, column: 5, scope: !450, inlinedAt: !347)
!452 = !DILocation(line: 138, column: 18, scope: !389, inlinedAt: !398, atomGroup: 11, atomRank: 2)
!453 = !DILocation(line: 138, column: 12, scope: !389, inlinedAt: !398)
!454 = !DILocation(line: 181, column: 5, scope: !334, inlinedAt: !347)
!455 = !DILocalVariable(name: "entries", arg: 1, scope: !456, file: !3, line: 154, type: !337)
!456 = distinct !DISubprogram(name: "singletons", scope: !3, file: !3, line: 154, type: !457, scopeLine: 154, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !459, keyInstructions: true)
!457 = !DISubroutineType(types: !458)
!458 = !{!6, !337, !6}
!459 = !{!455, !460, !461, !462}
!460 = !DILocalVariable(name: "n", arg: 2, scope: !456, file: !3, line: 154, type: !6)
!461 = !DILocalVariable(name: "count", scope: !456, file: !3, line: 155, type: !6)
!462 = !DILocalVariable(name: "i", scope: !463, file: !3, line: 156, type: !6)
!463 = distinct !DILexicalBlock(scope: !456, file: !3, line: 156, column: 5)
!464 = !DILocation(line: 0, scope: !456, inlinedAt: !465)
!465 = distinct !DILocation(line: 182, column: 37, scope: !334, inlinedAt: !347)
!466 = !DILocation(line: 0, scope: !463, inlinedAt: !465)
!467 = !DILocation(line: 156, column: 5, scope: !463, inlinedAt: !465)
!468 = !DILocation(line: 0, scope: !388, inlinedAt: !398)
!469 = !DILocation(line: 0, scope: !389, inlinedAt: !398)
!470 = !DILocation(line: 135, column: 33, scope: !471, inlinedAt: !398)
!471 = distinct !DILexicalBlock(scope: !472, file: !3, line: 134, column: 33)
!472 = distinct !DILexicalBlock(scope: !388, file: !3, line: 134, column: 5)
!473 = !DILocation(line: 135, column: 26, scope: !471, inlinedAt: !398)
!474 = !DILocation(line: 135, column: 63, scope: !471, inlinedAt: !398)
!475 = !DILocation(line: 135, column: 52, scope: !471, inlinedAt: !398)
!476 = !DILocation(line: 135, column: 50, scope: !471, inlinedAt: !398)
!477 = !DILocation(line: 135, column: 17, scope: !471, inlinedAt: !398, atomGroup: 6, atomRank: 2)
!478 = !DILocation(line: 136, column: 15, scope: !471, inlinedAt: !398, atomGroup: 7, atomRank: 2)
!479 = !DILocation(line: 134, column: 29, scope: !472, inlinedAt: !398, atomGroup: 8, atomRank: 2)
!480 = !DILocation(line: 134, column: 23, scope: !472, inlinedAt: !398, atomGroup: 4, atomRank: 1)
!481 = !DILocation(line: 134, column: 5, scope: !388, inlinedAt: !398, atomGroup: 5, atomRank: 1)
!482 = distinct !{!482, !387, !483, !175}
!483 = !DILocation(line: 137, column: 5, scope: !388, inlinedAt: !398)
!484 = !DILocation(line: 156, column: 32, scope: !485, inlinedAt: !465, atomGroup: 41, atomRank: 1)
!485 = distinct !DILexicalBlock(scope: !463, file: !3, line: 156, column: 5)
!486 = !DILocation(line: 156, scope: !463, inlinedAt: !465, atomGroup: 2, atomRank: 2)
!487 = !DILocation(line: 156, column: 35, scope: !485, inlinedAt: !465)
!488 = !DILocation(line: 156, column: 46, scope: !485, inlinedAt: !465)
!489 = !DILocation(line: 156, column: 52, scope: !485, inlinedAt: !465)
!490 = !DILocation(line: 156, column: 5, scope: !463, inlinedAt: !465, atomGroup: 4, atomRank: 1)
!491 = !DILocation(line: 157, column: 14, scope: !492, inlinedAt: !465, atomGroup: 5, atomRank: 2)
!492 = distinct !DILexicalBlock(scope: !485, file: !3, line: 156, column: 63)
!493 = !DILocation(line: 156, column: 27, scope: !485, inlinedAt: !465, atomGroup: 3, atomRank: 2)
!494 = !DILocation(line: 156, column: 32, scope: !485, inlinedAt: !465, atomGroup: 3, atomRank: 1)
!495 = distinct !{!495, !467, !496, !175}
!496 = !DILocation(line: 158, column: 5, scope: !463, inlinedAt: !465)
!497 = !DILocation(line: 182, column: 5, scope: !334, inlinedAt: !347)
!498 = !DILocalVariable(name: "table", arg: 1, scope: !499, file: !3, line: 64, type: !297)
!499 = distinct !DISubprogram(name: "table_lookup", scope: !3, file: !3, line: 64, type: !500, scopeLine: 64, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !502, keyInstructions: true)
!500 = !DISubroutineType(types: !501)
!501 = !{!6, !297, !74}
!502 = !{!498, !503, !504, !505, !507}
!503 = !DILocalVariable(name: "word", arg: 2, scope: !499, file: !3, line: 64, type: !74)
!504 = !DILocalVariable(name: "index", scope: !499, file: !3, line: 65, type: !12)
!505 = !DILocalVariable(name: "probe", scope: !506, file: !3, line: 66, type: !6)
!506 = distinct !DILexicalBlock(scope: !499, file: !3, line: 66, column: 5)
!507 = !DILocalVariable(name: "slot", scope: !508, file: !3, line: 67, type: !337)
!508 = distinct !DILexicalBlock(scope: !509, file: !3, line: 66, column: 54)
!509 = distinct !DILexicalBlock(scope: !506, file: !3, line: 66, column: 5)
!510 = !DILocation(line: 0, scope: !499, inlinedAt: !511)
!511 = distinct !DILocation(line: 192, column: 17, scope: !2)
!512 = !DILocation(line: 0, scope: !222, inlinedAt: !513)
!513 = distinct !DILocation(line: 65, column: 26, scope: !499, inlinedAt: !511)
!514 = !DILocation(line: 0, scope: !228, inlinedAt: !513)
!515 = !DILocation(line: 66, column: 5, scope: !506, inlinedAt: !511)
!516 = !DILocation(line: 0, scope: !506, inlinedAt: !511)
!517 = !DILocation(line: 67, column: 37, scope: !508, inlinedAt: !511)
!518 = !DILocation(line: 67, column: 37, scope: !508, inlinedAt: !511, atomGroup: 5, atomRank: 2)
!519 = !DILocation(line: 0, scope: !508, inlinedAt: !511)
!520 = !DILocation(line: 68, column: 19, scope: !521, inlinedAt: !511)
!521 = distinct !DILexicalBlock(scope: !508, file: !3, line: 68, column: 13)
!522 = !DILocation(line: 68, column: 25, scope: !521, inlinedAt: !511, atomGroup: 6, atomRank: 2)
!523 = !DILocation(line: 68, column: 25, scope: !521, inlinedAt: !511, atomGroup: 6, atomRank: 1)
!524 = !DILocation(line: 71, column: 13, scope: !525, inlinedAt: !511)
!525 = distinct !DILexicalBlock(scope: !508, file: !3, line: 71, column: 13)
!526 = !DILocation(line: 71, column: 38, scope: !525, inlinedAt: !511, atomGroup: 8, atomRank: 2)
!527 = !DILocation(line: 71, column: 38, scope: !525, inlinedAt: !511, atomGroup: 8, atomRank: 1)
!528 = !DILocation(line: 74, column: 24, scope: !508, inlinedAt: !511)
!529 = !DILocation(line: 66, column: 50, scope: !509, inlinedAt: !511, atomGroup: 11, atomRank: 2)
!530 = !DILocation(line: 66, column: 31, scope: !509, inlinedAt: !511, atomGroup: 3, atomRank: 1)
!531 = !DILocation(line: 66, column: 5, scope: !506, inlinedAt: !511, atomGroup: 4, atomRank: 1)
!532 = distinct !{!532, !515, !533, !175}
!533 = !DILocation(line: 75, column: 5, scope: !506, inlinedAt: !511)
!534 = !DILocation(line: 0, scope: !499, inlinedAt: !535)
!535 = distinct !DILocation(line: 193, column: 16, scope: !2)
!536 = !DILocation(line: 0, scope: !222, inlinedAt: !537)
!537 = distinct !DILocation(line: 65, column: 26, scope: !499, inlinedAt: !535)
!538 = !DILocation(line: 0, scope: !228, inlinedAt: !537)
!539 = !DILocation(line: 66, column: 5, scope: !506, inlinedAt: !535)
!540 = !DILocation(line: 0, scope: !506, inlinedAt: !535)
!541 = !DILocation(line: 67, column: 37, scope: !508, inlinedAt: !535)
!542 = !DILocation(line: 67, column: 37, scope: !508, inlinedAt: !535, atomGroup: 5, atomRank: 2)
!543 = !DILocation(line: 0, scope: !508, inlinedAt: !535)
!544 = !DILocation(line: 68, column: 19, scope: !521, inlinedAt: !535)
!545 = !DILocation(line: 68, column: 25, scope: !521, inlinedAt: !535, atomGroup: 6, atomRank: 2)
!546 = !DILocation(line: 68, column: 25, scope: !521, inlinedAt: !535, atomGroup: 6, atomRank: 1)
!547 = !DILocation(line: 71, column: 13, scope: !525, inlinedAt: !535)
!548 = !DILocation(line: 71, column: 38, scope: !525, inlinedAt: !535, atomGroup: 8, atomRank: 2)
!549 = !DILocation(line: 71, column: 38, scope: !525, inlinedAt: !535, atomGroup: 8, atomRank: 1)
!550 = !DILocation(line: 74, column: 24, scope: !508, inlinedAt: !535)
!551 = !DILocation(line: 66, column: 50, scope: !509, inlinedAt: !535, atomGroup: 11, atomRank: 2)
!552 = !DILocation(line: 66, column: 31, scope: !509, inlinedAt: !535, atomGroup: 3, atomRank: 1)
!553 = !DILocation(line: 66, column: 5, scope: !506, inlinedAt: !535, atomGroup: 4, atomRank: 1)
!554 = distinct !{!554, !539, !555, !175}
!555 = !DILocation(line: 75, column: 5, scope: !506, inlinedAt: !535)
!556 = !DILocation(line: 194, column: 5, scope: !2)
!557 = !DILocation(line: 195, column: 18, scope: !2, atomGroup: 6, atomRank: 2)
!558 = !DILocation(line: 195, column: 22, scope: !2, atomGroup: 6, atomRank: 1)
!559 = !DILocation(line: 195, column: 12, scope: !2, atomGroup: 7, atomRank: 2)
!560 = !DILocation(line: 195, column: 5, scope: !2, atomGroup: 7, atomRank: 1)
!561 = !DISubprogram(name: "printf", scope: !562, file: !562, line: 363, type: !563, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!562 = !DIFile(filename: "/usr/include/stdio.h", directory: "", checksumkind: CSK_MD5, checksum: "1e435c46987a169d9f9186f63a512303")
!563 = !DISubroutineType(types: !564)
!564 = !{!6, !565, null}
!565 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !74)
!566 = !DISubprogram(name: "fprintf", scope: !562, file: !562, line: 357, type: !567, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!567 = !DISubroutineType(types: !568)
!568 = !{!6, !569, !565, null}
!569 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !570)
!570 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !571, size: 64)
!571 = !DIDerivedType(tag: DW_TAG_typedef, name: "FILE", file: !572, line: 7, baseType: !573)
!572 = !DIFile(filename: "/usr/include/x86_64-linux-gnu/bits/types/FILE.h", directory: "", checksumkind: CSK_MD5, checksum: "571f9fb6223c42439075fdde11a0de5d")
!573 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "_IO_FILE", file: !574, line: 49, size: 1728, elements: !575)
!574 = !DIFile(filename: "/usr/include/x86_64-linux-gnu/bits/types/struct_FILE.h", directory: "", checksumkind: CSK_MD5, checksum: "7a6d4a00a37ee6b9a40cd04bd01f5d00")
!575 = !{!576, !577, !578, !579, !580, !581, !582, !583, !584, !585, !586, !587, !588, !591, !593, !594, !595, !598, !599, !601, !605, !608, !610, !613, !616, !617, !618, !619, !620}
!576 = !DIDerivedType(tag: DW_TAG_member, name: "_flags", scope: !573, file: !574, line: 51, baseType: !6, size: 32)
!577 = !DIDerivedType(tag: DW_TAG_member, name: "_IO_read_ptr", scope: !573, file: !574, line: 54, baseType: !143, size: 64, offset: 64)
!578 = !DIDerivedType(tag: DW_TAG_member, name: "_IO_read_end", scope: !573, file: !574, line: 55, baseType: !143, size: 64, offset: 128)
!579 = !DIDerivedType(tag: DW_TAG_member, name: "_IO_read_base", scope: !573, file: !574, line: 56, baseType: !143, size: 64, offset: 192)
!580 = !DIDerivedType(tag: DW_TAG_member, name: "_IO_write_base", scope: !573, file: !574, line: 57, baseType: !143, size: 64, offset: 256)
!581 = !DIDerivedType(tag: DW_TAG_member, name: "_IO_write_ptr", scope: !573, file: !574, line: 58, baseType: !143, size: 64, offset: 320)
!582 = !DIDerivedType(tag: DW_TAG_member, name: "_IO_write_end", scope: !573, file: !574, line: 59, baseType: !143, size: 64, offset: 384)
!583 = !DIDerivedType(tag: DW_TAG_member, name: "_IO_buf_base", scope: !573, file: !574, line: 60, baseType: !143, size: 64, offset: 448)
!584 = !DIDerivedType(tag: DW_TAG_member, name: "_IO_buf_end", scope: !573, file: !574, line: 61, baseType: !143, size: 64, offset: 512)
!585 = !DIDerivedType(tag: DW_TAG_member, name: "_IO_save_base", scope: !573, file: !574, line: 64, baseType: !143, size: 64, offset: 576)
!586 = !DIDerivedType(tag: DW_TAG_member, name: "_IO_backup_base", scope: !573, file: !574, line: 65, baseType: !143, size: 64, offset: 640)
!587 = !DIDerivedType(tag: DW_TAG_member, name: "_IO_save_end", scope: !573, file: !574, line: 66, baseType: !143, size: 64, offset: 704)
!588 = !DIDerivedType(tag: DW_TAG_member, name: "_markers", scope: !573, file: !574, line: 68, baseType: !589, size: 64, offset: 768)
!589 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !590, size: 64)
!590 = !DICompositeType(tag: DW_TAG_structure_type, name: "_IO_marker", file: !574, line: 36, flags: DIFlagFwdDecl)
!591 = !DIDerivedType(tag: DW_TAG_member, name: "_chain", scope: !573, file: !574, line: 70, baseType: !592, size: 64, offset: 832)
!592 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !573, size: 64)
!593 = !DIDerivedType(tag: DW_TAG_member, name: "_fileno", scope: !573, file: !574, line: 72, baseType: !6, size: 32, offset: 896)
!594 = !DIDerivedType(tag: DW_TAG_member, name: "_flags2", scope: !573, file: !574, line: 73, baseType: !6, size: 32, offset: 928)
!595 = !DIDerivedType(tag: DW_TAG_member, name: "_old_offset", scope: !573, file: !574, line: 74, baseType: !596, size: 64, offset: 960)
!596 = !DIDerivedType(tag: DW_TAG_typedef, name: "__off_t", file: !597, line: 152, baseType: !34)
!597 = !DIFile(filename: "/usr/include/x86_64-linux-gnu/bits/types.h", directory: "", checksumkind: CSK_MD5, checksum: "e1865d9fe29fe1b5ced550b7ba458f9e")
!598 = !DIDerivedType(tag: DW_TAG_member, name: "_cur_column", scope: !573, file: !574, line: 77, baseType: !28, size: 16, offset: 1024)
!599 = !DIDerivedType(tag: DW_TAG_member, name: "_vtable_offset", scope: !573, file: !574, line: 78, baseType: !600, size: 8, offset: 1040)
!600 = !DIBasicType(name: "signed char", size: 8, encoding: DW_ATE_signed_char)
!601 = !DIDerivedType(tag: DW_TAG_member, name: "_shortbuf", scope: !573, file: !574, line: 79, baseType: !602, size: 8, offset: 1048)
!602 = !DICompositeType(tag: DW_TAG_array_type, baseType: !29, size: 8, elements: !603)
!603 = !{!604}
!604 = !DISubrange(count: 1)
!605 = !DIDerivedType(tag: DW_TAG_member, name: "_lock", scope: !573, file: !574, line: 81, baseType: !606, size: 64, offset: 1088)
!606 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !607, size: 64)
!607 = !DIDerivedType(tag: DW_TAG_typedef, name: "_IO_lock_t", file: !574, line: 43, baseType: null)
!608 = !DIDerivedType(tag: DW_TAG_member, name: "_offset", scope: !573, file: !574, line: 89, baseType: !609, size: 64, offset: 1152)
!609 = !DIDerivedType(tag: DW_TAG_typedef, name: "__off64_t", file: !597, line: 153, baseType: !34)
!610 = !DIDerivedType(tag: DW_TAG_member, name: "_codecvt", scope: !573, file: !574, line: 91, baseType: !611, size: 64, offset: 1216)
!611 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !612, size: 64)
!612 = !DICompositeType(tag: DW_TAG_structure_type, name: "_IO_codecvt", file: !574, line: 37, flags: DIFlagFwdDecl)
!613 = !DIDerivedType(tag: DW_TAG_member, name: "_wide_data", scope: !573, file: !574, line: 92, baseType: !614, size: 64, offset: 1280)
!614 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !615, size: 64)
!615 = !DICompositeType(tag: DW_TAG_structure_type, name: "_IO_wide_data", file: !574, line: 38, flags: DIFlagFwdDecl)
!616 = !DIDerivedType(tag: DW_TAG_member, name: "_freeres_list", scope: !573, file: !574, line: 93, baseType: !592, size: 64, offset: 1344)
!617 = !DIDerivedType(tag: DW_TAG_member, name: "_freeres_buf", scope: !573, file: !574, line: 94, baseType: !33, size: 64, offset: 1408)
!618 = !DIDerivedType(tag: DW_TAG_member, name: "__pad5", scope: !573, file: !574, line: 95, baseType: !30, size: 64, offset: 1472)
!619 = !DIDerivedType(tag: DW_TAG_member, name: "_mode", scope: !573, file: !574, line: 96, baseType: !6, size: 32, offset: 1536)
!620 = !DIDerivedType(tag: DW_TAG_member, name: "_unused2", scope: !573, file: !574, line: 98, baseType: !621, size: 160, offset: 1568)
!621 = !DICompositeType(tag: DW_TAG_array_type, baseType: !29, size: 160, elements: !622)
!622 = !{!623}
!623 = !DISubrange(count: 20)
!624 = !DISubprogram(name: "__ctype_b_loc", scope: !11, file: !11, line: 79, type: !625, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!625 = !DISubroutineType(types: !626)
!626 = !{!627}
!627 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !628, size: 64)
!628 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !629, size: 64)
!629 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !28)
!630 = !DISubprogram(name: "__ctype_tolower_loc", scope: !11, file: !11, line: 81, type: !631, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!631 = !DISubroutineType(types: !632)
!632 = !{!633}
!633 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !634, size: 64)
!634 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !635, size: 64)
!635 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !636)
!636 = !DIDerivedType(tag: DW_TAG_typedef, name: "__int32_t", file: !597, line: 41, baseType: !6)
!637 = !DISubprogram(name: "strncpy", scope: !638, file: !638, line: 144, type: !639, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!638 = !DIFile(filename: "/usr/include/string.h", directory: "", checksumkind: CSK_MD5, checksum: "165db1185644f68894fa9e0d17055d70")
!639 = !DISubroutineType(types: !640)
!640 = !{!143, !641, !565, !30}
!641 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !143)
!642 = !DISubprogram(name: "strcmp", scope: !638, file: !638, line: 156, type: !643, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!643 = !DISubroutineType(types: !644)
!644 = !{!6, !74, !74}
!645 = !DISubprogram(name: "qsort", scope: !646, file: !646, line: 970, type: !647, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!646 = !DIFile(filename: "/usr/include/stdlib.h", directory: "", checksumkind: CSK_MD5, checksum: "7fa2ecb2348a66f8b44ab9a15abd0b72")
!647 = !DISubroutineType(types: !648)
!648 = !{null, !33, !30, !30, !649}
!649 = !DIDerivedType(tag: DW_TAG_typedef, name: "__compar_fn_t", file: !646, line: 948, baseType: !650)
!650 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !651, size: 64)
!651 = !DISubroutineType(types: !652)
!652 = !{!6, !653, !653}
!653 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !654, size: 64)
!654 = !DIDerivedType(tag: DW_TAG_const_type, baseType: null)
!655 = distinct !DISubprogram(name: "by_count", scope: !3, file: !3, line: 111, type: !651, scopeLine: 111, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !656, keyInstructions: true)
!656 = !{!657, !658, !659, !660}
!657 = !DILocalVariable(name: "a", arg: 1, scope: !655, file: !3, line: 111, type: !653)
!658 = !DILocalVariable(name: "b", arg: 2, scope: !655, file: !3, line: 111, type: !653)
!659 = !DILocalVariable(name: "x", scope: !655, file: !3, line: 112, type: !337)
!660 = !DILocalVariable(name: "y", scope: !655, file: !3, line: 113, type: !337)
!661 = !DILocation(line: 0, scope: !655)
!662 = !DILocation(line: 114, column: 12, scope: !663)
!663 = distinct !DILexicalBlock(scope: !655, file: !3, line: 114, column: 9)
!664 = !DILocation(line: 114, column: 24, scope: !663)
!665 = !DILocation(line: 114, column: 18, scope: !663, atomGroup: 3, atomRank: 2)
!666 = !DILocation(line: 114, column: 18, scope: !663, atomGroup: 3, atomRank: 1)
!667 = !DILocation(line: 115, column: 25, scope: !668, atomGroup: 4, atomRank: 2)
!668 = distinct !DILexicalBlock(scope: !663, file: !3, line: 114, column: 31)
!669 = !DILocation(line: 115, column: 9, scope: !668, atomGroup: 4, atomRank: 1)
!670 = !DILocation(line: 117, column: 15, scope: !655)
!671 = !DILocation(line: 117, column: 31, scope: !655)
!672 = !DILocation(line: 117, column: 26, scope: !655, atomGroup: 5, atomRank: 2)
!673 = !DILocation(line: 117, column: 5, scope: !655, atomGroup: 5, atomRank: 1)
!674 = !DILocation(line: 118, column: 1, scope: !655, atomGroup: 6, atomRank: 1)
!675 = !DISubprogram(name: "putc", scope: !562, file: !562, line: 612, type: !676, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!676 = !DISubroutineType(types: !677)
!677 = !{!6, !6, !570}
!678 = !DISubprogram(name: "strlen", scope: !638, file: !638, line: 407, type: !679, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!679 = !DISubroutineType(types: !680)
!680 = !{!32, !74}
