#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <kmalloc.h>
#include <rb_tree.h>
#include <assert.h>

/* rb_node_create - create a new rb_node */
static inline rb_node *
rb_node_create(void) {
    return kmalloc(sizeof(rb_node));
}

/* rb_tree_empty - tests if tree is empty */
static inline bool
rb_tree_empty(rb_tree *tree) {
    rb_node *nil = tree->nil, *root = tree->root;
    return root->left == nil;
}

/* *
 * rb_tree_create - creates a new red-black tree, the 'compare' function
 * is required and returns 'NULL' if failed.
 *
 * Note that, root->left should always point to the node that is the root
 * of the tree. And nil points to a 'NULL' node which should always be
 * black and may have arbitrary children and parent node.
 * */
rb_tree *
rb_tree_create(int (*compare)(rb_node *node1, rb_node *node2)) {
    assert(compare != NULL);

    rb_tree *tree;
    rb_node *nil, *root;

    if ((tree = kmalloc(sizeof(rb_tree))) == NULL) {
        goto bad_tree;
    }

    tree->compare = compare;

    if ((nil = rb_node_create()) == NULL) {
        goto bad_node_cleanup_tree;
    }

    nil->parent = nil->left = nil->right = nil;
    nil->red = 0;
    tree->nil = nil;

    if ((root = rb_node_create()) == NULL) {
        goto bad_node_cleanup_nil;
    }

    root->parent = root->left = root->right = nil;
    root->red = 0;
    tree->root = root;
    return tree;

bad_node_cleanup_nil:
    kfree(nil);
bad_node_cleanup_tree:
    kfree(tree);
bad_tree:
    return NULL;
}

/* *
 * FUNC_ROTATE - rotates as described in "Introduction to Algorithm".
 *
 * For example, FUNC_ROTATE(rb_left_rotate, left, right) can be expaned to a
 * left-rotate function, which requires an red-black 'tree' and a node 'x'
 * to be rotated on. Basically, this function, named rb_left_rotate, makes the
 * parent of 'x' be the left child of 'x', 'x' the parent of its parent before
 * rotation and finally fixes other nodes accordingly.
 *
 * FUNC_ROTATE(xx, left, right) means left-rotate,
 * and FUNC_ROTATE(xx, right, left) means right-rotate.
 * */
#define FUNC_ROTATE(func_name, _left, _right)                   \
static void                                                     \
func_name(rb_tree *tree, rb_node *x) {                          \
    rb_node *nil = tree->nil, *y = x->_right;                   \
    assert(x != tree->root && x != nil && y != nil);            \
    x->_right = y->_left;                                       \
    if (y->_left != nil) {                                      \
        y->_left->parent = x;                                   \
    }                                                           \
    y->parent = x->parent;                                      \
    if (x == x->parent->_left) {                                \
        x->parent->_left = y;                                   \
    }                                                           \
    else {                                                      \
        x->parent->_right = y;                                  \
    }                                                           \
    y->_left = x;                                               \
    x->parent = y;                                              \
    assert(!(nil->red));                                        \
}

FUNC_ROTATE(rb_left_rotate, left, right);
FUNC_ROTATE(rb_right_rotate, right, left);

#undef FUNC_ROTATE

#define COMPARE(tree, node1, node2)                             \
    ((tree))->compare((node1), (node2))

/* *
 * rb_insert_binary - insert @node to red-black @tree as if it were
 * a regular binary tree. This function is only intended to be called
 * by function rb_insert.
 * */
static inline void
rb_insert_binary(rb_tree *tree, rb_node *node) {
    rb_node *x, *y, *z = node, *nil = tree->nil, *root = tree->root;

    z->left = z->right = nil;
    y = root, x = y->left;
    while (x != nil) {
        y = x;
        x = (COMPARE(tree, x, node) > 0) ? x->left : x->right;
    }
    z->parent = y;
    if (y == root || COMPARE(tree, y, z) > 0) {
        y->left = z;
    }
    else {
        y->right = z;
    }
}

/* rb_insert - insert a node to red-black tree */
void
rb_insert(rb_tree *tree, rb_node *node) {
    rb_insert_binary(tree, node);
    node->red = 1;

    rb_node *x = node, *y;

#define RB_INSERT_SUB(_left, _right)                            \
    do {                                                        \
        y = x->parent->parent->_right;                          \
        if (y->red) {                                           \
            x->parent->red = 0;                                 \
            y->red = 0;                                         \
            x->parent->parent->red = 1;                         \
            x = x->parent->parent;                              \
        }                                                       \
        else {                                                  \
            if (x == x->parent->_right) {                       \
                x = x->parent;                                  \
                rb_##_left##_rotate(tree, x);                   \
            }                                                   \
            x->parent->red = 0;                                 \
            x->parent->parent->red = 1;                         \
            rb_##_right##_rotate(tree, x->parent->parent);      \
        }                                                       \
    } while (0)

    while (x->parent->red) {
        if (x->parent == x->parent->parent->left) {
            RB_INSERT_SUB(left, right);
        }
        else {
            RB_INSERT_SUB(right, left);
        }
    }
    tree->root->left->red = 0;
    assert(!(tree->nil->red) && !(tree->root->red));

#undef RB_INSERT_SUB
}

/* *
 * rb_tree_successor - returns the successor of @node, or nil
 * if no successor exists. Make sure that @node must belong to @tree,
 * and this function should only be called by rb_node_prev.
 * */
static inline rb_node *
rb_tree_successor(rb_tree *tree, rb_node *node) {
    rb_node *x = node, *y, *nil = tree->nil;

    if ((y = x->right) != nil) {
        while (y->left != nil) {
            y = y->left;
        }
        return y;
    }
    else {
        y = x->parent;
        while (x == y->right) {
            x = y, y = y->parent;
        }
        if (y == tree->root) {
            return nil;
        }
        return y;
    }
}

/* *
 * rb_tree_predecessor - returns the predecessor of @node, or nil
 * if no predecessor exists, likes rb_tree_successor.
 * */
static inline rb_node *
rb_tree_predecessor(rb_tree *tree, rb_node *node) {
    rb_node *x = node, *y, *nil = tree->nil;

    if ((y = x->left) != nil) {
        while (y->right != nil) {
            y = y->right;
        }
        return y;
    }
    else {
        y = x->parent;
        while (x == y->left) {
            if (y == tree->root) {
                return nil;
            }
            x = y, y = y->parent;
        }
        return y;
    }
}

/* *
 * rb_search - returns a node with value 'equal' to @key (according to
 * function @compare). If there're multiple nodes with value 'equal' to @key,
 * the functions returns the one highest in the tree.
 * */
rb_node *
rb_search(rb_tree *tree, int (*compare)(rb_node *node, void *key), void *key) {
    rb_node *nil = tree->nil, *node = tree->root->left;
    int r;
    while (node != nil && (r = compare(node, key)) != 0) {
        node = (r > 0) ? node->left : node->right;
    }
    return (node != nil) ? node : NULL;
}

/* *
 * rb_delete_fixup - performs rotations and changes colors to restore
 * red-black properties after a node is deleted.
 * */
static void
rb_delete_fixup(rb_tree *tree, rb_node *node) {
    rb_node *x = node, *w, *root = tree->root->left;

#define RB_DELETE_FIXUP_SUB(_left, _right)                      \
    do {                                                        \
        w = x->parent->_right;                                  \
        if (w->red) {                                           \
            w->red = 0;                                         \
            x->parent->red = 1;                                 \
            rb_##_left##_rotate(tree, x->parent);               \
            w = x->parent->_right;                              \
        }                                                       \
        if (!w->_left->red && !w->_right->red) {                \
            w->red = 1;                                         \
            x = x->parent;                                      \
        }                                                       \
        else {                                                  \
            if (!w->_right->red) {                              \
                w->_left->red = 0;                              \
                w->red = 1;                                     \
                rb_##_right##_rotate(tree, w);                  \
                w = x->parent->_right;                          \
            }                                                   \
            w->red = x->parent->red;                            \
            x->parent->red = 0;                                 \
            w->_right->red = 0;                                 \
            rb_##_left##_rotate(tree, x->parent);               \
            x = root;                                           \
        }                                                       \
    } while (0)

    while (x != root && !x->red) {
        if (x == x->parent->left) {
            RB_DELETE_FIXUP_SUB(left, right);
        }
        else {
            RB_DELETE_FIXUP_SUB(right, left);
        }
    }
    x->red = 0;

#undef RB_DELETE_FIXUP_SUB
}

/* *
 * rb_delete - deletes @node from @tree, and calls rb_delete_fixup to
 * restore red-black properties.
 * */
void
rb_delete(rb_tree *tree, rb_node *node) {
    rb_node *x, *y, *z = node;
    rb_node *nil = tree->nil, *root = tree->root;

    y = (z->left == nil || z->right == nil) ? z : rb_tree_successor(tree, z);
    x = (y->left != nil) ? y->left : y->right;

    assert(y != root && y != nil);

    x->parent = y->parent;
    if (y == y->parent->left) {
        y->parent->left = x;
    }
    else {
        y->parent->right = x;
    }

    bool need_fixup = !(y->red);

    if (y != z) {
        if (z == z->parent->left) {
            z->parent->left = y;
        }
        else {
            z->parent->right = y;
        }
        z->left->parent = z->right->parent = y;
        *y = *z;
    }
    if (need_fixup) {
        rb_delete_fixup(tree, x);
    }
}

/* rb_tree_destroy - destroy a tree and free memory */
void
rb_tree_destroy(rb_tree *tree) {
    kfree(tree->root);
    kfree(tree->nil);
    kfree(tree);
}

/* *
 * rb_node_prev - returns the predecessor node of @node in @tree,
 * or 'NULL' if no predecessor exists.
 * */
rb_node *
rb_node_prev(rb_tree *tree, rb_node *node) {
    rb_node *prev = rb_tree_predecessor(tree, node);
    return (prev != tree->nil) ? prev : NULL;
}

/* *
 * rb_node_next - returns the successor node of @node in @tree,
 * or 'NULL' if no successor exists.
 * */
rb_node *
rb_node_next(rb_tree *tree, rb_node *node) {
    rb_node *next = rb_tree_successor(tree, node);
    return (next != tree->nil) ? next : NULL;
}

/* rb_node_root - returns the root node of a @tree, or 'NULL' if tree is empty */
rb_node *
rb_node_root(rb_tree *tree) {
    rb_node *node = tree->root->left;
    return (node != tree->nil) ? node : NULL;
}

/* rb_node_left - gets the left child of @node, or 'NULL' if no such node */
rb_node *
rb_node_left(rb_tree *tree, rb_node *node) {
    rb_node *left = node->left;
    return (left != tree->nil) ? left : NULL;
}

/* rb_node_right - gets the right child of @node, or 'NULL' if no such node */
rb_node *
rb_node_right(rb_tree *tree, rb_node *node) {
    rb_node *right = node->right;
    return (right != tree->nil) ? right : NULL;
}

int
check_tree(rb_tree *tree, rb_node *node) {
    rb_node *nil = tree->nil;
    if (node == nil) {
        assert(!node->red);
        return 1;
    }
    if (node->left != nil) {
        assert(COMPARE(tree, node, node->left) >= 0);
        assert(node->left->parent == node);
    }
    if (node->right != nil) {
        assert(COMPARE(tree, node, node->right) <= 0);
        assert(node->right->parent == node);
    }
    if (node->red) {
        assert(!node->left->red && !node->right->red);
    }
    int hb_left = check_tree(tree, node->left);
    int hb_right = check_tree(tree, node->right);
    assert(hb_left == hb_right);
    int hb = hb_left;
    if (!node->red) {
        hb ++;
    }
    return hb;
}

static void *
check_safe_kmalloc(size_t size) {
    void *ret = kmalloc(size);
    assert(ret != NULL);
    return ret;
}

struct check_data {
    long data;
    rb_node rb_link;
};

#define rbn2data(node)              \
    (to_struct(node, struct check_data, rb_link))

static inline int
check_compare1(rb_node *node1, rb_node *node2) {
    return rbn2data(node1)->data - rbn2data(node2)->data;
}

static inline int
check_compare2(rb_node *node, void *key) {
    return rbn2data(node)->data - (long)key;
}

void
check_rb_tree(void) {
    rb_tree *tree = rb_tree_create(check_compare1);
    assert(tree != NULL);

    rb_node *nil = tree->nil, *root = tree->root;
    assert(!nil->red && root->left == nil);

    int total = 1000;
    struct check_data **all = check_safe_kmalloc(sizeof(struct check_data *) * total);

    long i;
    for (i = 0; i < total; i ++) {
        all[i] = check_safe_kmalloc(sizeof(struct check_data));
        all[i]->data = i;
    }

    int *mark = check_safe_kmalloc(sizeof(int) * total);
    memset(mark, 0, sizeof(int) * total);

    for (i = 0; i < total; i ++) {
        mark[all[i]->data] = 1;
    }
    for (i = 0; i < total; i ++) {
        assert(mark[i] == 1);
    }

    for (i = 0; i < total; i ++) {
        int j = (rand() % (total - i)) + i;
        struct check_data *z = all[i];
        all[i] = all[j];
        all[j] = z;
    }

    memset(mark, 0, sizeof(int) * total);
    for (i = 0; i < total; i ++) {
        mark[all[i]->data] = 1;
    }
    for (i = 0; i < total; i ++) {
        assert(mark[i] == 1);
    }

    for (i = 0; i < total; i ++) {
        rb_insert(tree, &(all[i]->rb_link));
        check_tree(tree, root->left);
    }

    rb_node *node;
    for (i = 0; i < total; i ++) {
        node = rb_search(tree, check_compare2, (void *)(all[i]->data));
        assert(node != NULL && node == &(all[i]->rb_link));
    }

    for (i = 0; i < total; i ++) {
        node = rb_search(tree, check_compare2, (void *)i);
        assert(node != NULL && rbn2data(node)->data == i);
        rb_delete(tree, node);
        check_tree(tree, root->left);
    }

    assert(!nil->red && root->left == nil);

    long max = 32;
    if (max > total) {
        max = total;
    }

    for (i = 0; i < max; i ++) {
        all[i]->data = max;
        rb_insert(tree, &(all[i]->rb_link));
        check_tree(tree, root->left);
    }

    for (i = 0; i < max; i ++) {
        node = rb_search(tree, check_compare2, (void *)max);
        assert(node != NULL && rbn2data(node)->data == max);
        rb_delete(tree, node);
        check_tree(tree, root->left);
    }

    assert(rb_tree_empty(tree));

    for (i = 0; i < total; i ++) {
        rb_insert(tree, &(all[i]->rb_link));
        check_tree(tree, root->left);
    }

    rb_tree_destroy(tree);

    for (i = 0; i < total; i ++) {
        kfree(all[i]);
    }

    kfree(mark);
    kfree(all);
}

