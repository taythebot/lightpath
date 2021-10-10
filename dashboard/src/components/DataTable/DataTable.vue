<template>
  <div class="card">
    <div v-if="title" class="card-header">
      <h3 class="card-title">{{ title }}</h3>
    </div>
    <div class="table-responsive">
      <table class="table card-table table-vcenter text-nowrap datatable">
        <thead>
          <tr>
            <th v-for="(header, index) of headers" :key="index">
              <slot :name="`header.${header.value}`" :header="header">
                {{ header.text }}
              </slot>
            </th>
          </tr>
        </thead>
        <tbody v-if="ready && total > 0">
          <tr v-for="(item, index) of currentItems" :key="index">
            <td
              v-for="(header, index) of headers"
              :key="index"
              :class="header.class"
            >
              <slot :name="`item.${header.value}`" :item="item">
                {{ item[header.value] }}
              </slot>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    <data-table-pagination
      v-if="!firstLoad && pagination && total > 0"
      :total="total"
      :limit="paginationLimit"
      v-model:current="currentPage"
    />
  </div>
</template>

<script>
import DataTablePagination from './DataTablePagination';

export default {
  name: 'DataTable',
  components: {
    DataTablePagination,
  },
  props: {
    title: {
      type: String,
      default: null,
    },
    headers: {
      type: Array,
      required: true,
    },
    items: {
      type: Array,
      default: () => [],
    },
    server: {
      type: Object,
      default: null,
    },
    pagination: {
      type: Boolean,
      default: false,
    },
    paginationLimit: {
      type: Number,
      default: 10,
    },
    query: {
      type: String,
      default: null,
    },
  },
  data: () => ({
    ready: true,
    error: false,
    waiting: false,
    firstLoad: true,
    currentItems: [],
    total: 0,
    currentPage: 0,
    sort: {
      column: null,
      direction: null,
    },
  }),
  watch: {
    server() {
      this.currentPage = 0;
      this.fetch();
    },
    currentPage() {
      this.fetch();
    },
    query() {
      if (!this.waiting) {
        setTimeout(() => {
          this.fetch();
          this.waiting = false;
        }, 1000);
      }
      this.waiting = true;
    },
  },
  mounted() {
    this.config = this.server;
    this.currentItems = this.items;
    if (this.server) {
      this.fetch();
    }
  },
  methods: {
    async fetch() {
      try {
        this.ready = false;
        const {
          currentPage,
          server,
          paginationLimit: limit,
          sort,
          query,
        } = this;
        if (server) {
          let url = server.url;
          if (!server.url.endsWith('&')) {
            url += '?';
          }
          url += `limit=${limit}&offset=${currentPage * limit}`;
          if (sort.column) {
            url += `&order=${sort.column}&dir=${sort.direction}`;
          }
          if (query) {
            url += `&query=${query}`;
          }

          const data = await this.$axios.get(url);
          this.currentItems = server.then(data);
          this.total = server.total(data);

          this.error = false;
          this.firstLoad = false;
        }
      } catch (error) {
        this.error = true;
      } finally {
        this.ready = true;
      }
    },
    handleSort(column) {
      this.sort.column = column;
      if (this.sort.column === column) {
        this.sort.direction = this.sort.direction === 'asc' ? 'desc' : 'asc';
      } else {
        this.sort.directoin = 'asc';
      }
      this.fetch();
    },
    refresh() {
      this.fetch();
    },
  },
};
</script>
